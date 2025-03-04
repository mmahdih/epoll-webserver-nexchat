use strict;
use warnings;
use Socket;
use IO::Epoll;
use Data::Dumper;
use HTTP::Request;
use Digest::SHA qw(sha1_base64);
use JSON;
use Term::ReadKey;
use URI::Escape;
use DBI;



# Including libraries
use lib qw(../);
use lib '.';
use HTTP_Request; # New library
use html_pages;
use HTTP_RESPONSE;
use webSocket_utils;
use menu_utils;
use smtp_server;
use user_control;






# Connect to PostgreSQL database
my $dsn = "DBI:Pg:dbname=mydb;host=localhost;port=5432";
my $db_user = 'postgres';
my $db_password = 'Admin.123';
my $dbh = DBI->connect($dsn, $db_user, $db_password, { AutoCommit => 1, RaiseError => 1 })
    or die "Failed to connect to PostgreSQL database: " . $DBI::errstr;

# Create table if not exists
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS users (
        user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        display_name VARCHAR(255),
        is_admin BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
}) or die "Create table failed: $dbh->errstr()";

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS chats (
        chat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        chat_name VARCHAR(100),
        is_group BOOLEAN,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
}) or die "Create table failed: $dbh->errstr()";

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS chat_participants (
        chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
        PRIMARY KEY (chat_id, user_id)
    )
}) or die "Create table failed: $dbh->errstr()";

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS messages (
        message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
        senderid UUID REFERENCES users(user_id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
}) or die "Create table failed: $dbh->errstr()";





# Prepare insert statement
my $sth_user = $dbh->prepare(q{INSERT INTO users (username, password, email, display_name, is_admin) VALUES (?, ?, ?, ?, ?)})
    or die "Prepare statement failed: $dbh->errstr()";
my $sth_chat = $dbh->prepare(q{INSERT INTO chats (chat_name, is_group) VALUES (?, ?)})
    or die "Prepare statement failed: $dbh->errstr()";
my $sth_message = $dbh->prepare(q{INSERT INTO messages (chat_id, sender_id, content) VALUES (?, ?, ?)})
    or die "Prepare statement failed: $dbh->errstr()";



# # Execute insert
# $sth->execute('Mahdi', 'Haidary', 'com')
#     or die "Insert failed: $dbh->errstr()";

# # Select data
# $sth = $dbh->prepare("SELECT lname, fname, ext FROM city")
#     or die "Prepare statement failed: $dbh->errstr()";

# $sth->execute() or die "Select failed: $dbh->errstr()";

# # Fetch and print results
# while (my @row = $sth->fetchrow_array()) {
#     print("$row[0], $row[1]\t$row[2]\n");
# }



my %epoll;
my %chat_epoll;

# Smtp server object
my $smtp_server = smtp_server->new();

# User control object
my $user_control = user_control->new();

# WebSocket server object
my $websocket_server = webSocket_utils->new();

# HTTP server object
my $http_request = HTTP_Request->new();


my $hehe;

# Routes 
my %get_routes = (
    '/'         => \&index,
    '/about'    => \&about,
    '/chat'     => \&chat,
    '/contact'  => \&contact,  # New GET route
    '/services' => \&services, # New GET route
);

my %post_routes = (
    '/'         => \&index,
    '/about'    => \&about,
    '/chat'     => \&chat,
    '/feedback' => \&feedback, # New POST route
);

my %websocket_routes = (
    '/chat'    => \&chat,
    '/support' => \&support_chat, # New WebSocket route
);


sub show_menu {
    system("clear");
    print "======= WebSocket Server =======\n";
    print "1. Start server\n";
    print "2. Stop server\n";
    print "3. Show log\n";
    print "4. Start SMTP server\n";
    print "0. Exit\n";
    print "================================\n";
}

sub stop_server {
    print "Stopping server...\n";
    menu_utils::write_log("INFO", "Socket", "Server stopped");
    
}

sub show_log {
    open my $fh, '<', 'server.log' or die "Cannot open log file: $!";
    while ( my $line = <$fh> ) {
        print $line;
    }
    close $fh;
}

sub main_loop {
    while (1) {
        show_menu();
        print 'Please choose an option: ';
        my $input = <STDIN>;
        chomp $input;

        if ( $input eq '1' ) {
            start_server();
        }
        elsif ( $input eq '2' ) {
            stop_server();
        }
        elsif ( $input eq '3' ) {
            show_log();
        }
        elsif ( $input eq '0' ) {
            last;
        }
        elsif ( $input eq '4' ) {
            $smtp_server->start();
        }
        else {
            print "Invalid option. Please try again.\n";
        }

        print "Press any key to continue...\n";
        ReadMode('raw');
        ReadKey(0);
        ReadMode('normal');
    }
}

sub start_server {
    print "Starting server on port 8080... \n";
    system("curl -d 'Server started on port 8080' 10.31.1.1/epoll_server");
    menu_utils::write_log("INFO", "Socket", "starting server on port 8080...");

    $epoll{server_epoll} = epoll_create(10);
    menu_utils::write_log("INFO", "Socket", "epoll created");

    # Create a TCP server socket
    socket( my $server, AF_INET, SOCK_STREAM, 0 ) 
        or die "socket: $!" && menu_utils::write_log("ERROR", "Socket", "socket: $!");

    setsockopt( $server, SOL_SOCKET, SO_REUSEADDR, 1 ) 
        or die "setsockopt: $!" && menu_utils::write_log("ERROR", "Socket", "setsockopt: $!");

    bind( $server, sockaddr_in( 8080, INADDR_ANY ) ) 
        or die "bind: $!" && menu_utils::write_log("ERROR", "Socket", "bind: $!");

    listen( $server, 5 ) 
        or die "listen: $!" && menu_utils::write_log("ERROR", "Socket", "listen: $!");


    # Add the server socket to epoll
    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_ADD, fileno($server), EPOLLIN ) >= 0
      or die "Failed to add server socket to epoll: $!\n" && menu_utils::write_log("ERROR", "Socket", "Failed to add server socket to epoll: $!\n");

    print "WebSocket server started on port 8080...\n";
    menu_utils::write_log("INFO", "Socket", "Server started");

    # Main loop to handle events
    while (1) {
        my $events = epoll_wait( $epoll{server_epoll}, 10, -1 );

        for my $event (@$events) {
            if ( $event->[0] == fileno $server ) {
                my $client_addr = accept( my $client_socket, $server );
                my ( $client_port, $client_ip ) = sockaddr_in($client_addr);
                my $client_ip_str = inet_ntoa($client_ip);
                print "Client connected from $client_ip_str:$client_port\n";
                system("curl -d 'Client connected from $client_ip_str:$client_port' 10.31.1.1/epoll_server");

                menu_utils::write_log("INFO", "Socket", "Client connected from $client_ip_str:$client_port");

                epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_ADD, fileno $client_socket, EPOLLIN ) >= 0
                  or die "Failed to add client socket to epoll: $!\n";

                # Store socket information
                $epoll{ fileno($client_socket) } = {
                    socket => $client_socket,
                    ip     => $client_ip_str,
                    port   => $client_port,
                    is_websocket => 0,
                };

                

            }
            elsif ( $event->[1] & EPOLLIN ) {
                handle_client($event->[0]);
            }
        }
    }
    
    # Cleanup
    $sth_chat->finish();
    $sth_user->finish();
    $sth_message->finish();
    $dbh->disconnect();
    # close $menu_utils::log;
}

sub handle_client {
    my ($fd) = @_;
    my $client = $epoll{$fd};
    my $buffer;
    
    my $bytes_read = sysread( $client->{socket}, $buffer, 1024);

    if (!$bytes_read) {
        print "OH NO! THE CLIENT DISCONNECTED\n";
        disconnect_client($fd);
        return;
    }

    if ($client->{is_websocket}) {
        $websocket_server->handle_websocket_message($fd, $buffer, \%epoll, \%chat_epoll, $hehe, $sth_chat, $sth_user, $sth_message, $dbh);
    } else {
        handle_http_request($fd, $buffer);
    }
}

sub handle_http_request {
    my ($fd, $buffer) = @_;
    my $client = $epoll{$fd};

    # just for fun
    # my $req = $http_request->parse($buffer);

    my $req = HTTP::Request->parse($buffer);
    $hehe = $req->uri;
    if (!$req) {
        print "Invalid HTTP req\n";
        menu_utils::write_log("ERROR", "Socket", "Invalid HTTP request");
        return;
    }
    print "test\n";
    my $method = $req->method;
    my $uri    = $req->uri;
    print "Method: $method, URI: $uri\n";

    # Handle WebSocket Upgrade
    if ( defined $req->header('Sec-WebSocket-Key') ) {
        # Upgrade to WebSocket and add to epoll
        $websocket_server->upgrade_to_websocket($fd, $buffer, %epoll);
        $epoll{$fd}{uri} = $uri;
        # Store client information in the chat_epoll
        $chat_epoll{$fd}{socket} = $client->{socket};
        print "Chat epoll: \n" . Dumper(\%chat_epoll) . "\n";

        return;
    }

    # Handle normal HTTP requests
    if ($method eq 'GET') {
        if ($uri eq '/test') {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("index"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd, "this is the test page");
        } elsif ($uri eq "/chat") {
            # check the cookies
            my $cookie = $req->header('Cookie') ;
            my $username = menu_utils::get_cookie_value($cookie, "username");
            print "Cookie: $cookie, username: $username\n";
            if ($cookie =~ /username=(.*)/) {
                my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("chat" , $1));
                send( $client->{socket}, $response, 0 );
            } else {
                my $response = HTTP_RESPONSE::REDIRECT_303(undef, "/login");
                send( $client->{socket}, $response, 0 );
            }
            disconnect_client($fd , "this is the chat page");
        } elsif ($uri eq "/") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("home"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the menu page");
        
        } elsif ($uri eq "/profile") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("profile"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the profile page");

        } elsif ($uri eq "/login") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("login"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the login page");

        } elsif ($uri eq "/register") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("register"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the register page");

        } elsif ($uri eq "/error") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("error"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the error page");

        } elsif ($uri eq "/friends") {

            # get all users from the users table in the database
            my $sth = $dbh->prepare("SELECT user_id, username, display_name FROM users");
            $sth->execute();
            my $users = $sth->fetchall_arrayref({});


            my $user_json = encode_json($users);
            print "User JSON: $user_json\n";


            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("friends"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the friends page");
        
        # } elsif ($uri =~ m/user_id=\/(.*)&friendid=(.*)/) {
        #url : chat?user_id=3
        } elsif ($uri =~ m/chat\?username=(.*)/) {
            
            my $cookie = $req->header('Cookie') ;
            my $my_username = menu_utils::get_cookie_value($cookie, "username");
            my $receiver_username = $1;
            print "Cookie: $cookie, username: $my_username\n";
            
            # $sth_user = $dbh->prepare("SELECT user_id FROM users WHERE username = ?");
            # $sth_user->execute($receiver_username);

            # my ($receiver_user_id) = $sth_user->fetchrow_array();

            # if (!$receiver_user_id) {
            #     my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("404"));
            #     send( $client->{socket}, $response, 0 );
            #     disconnect_client($fd , "this is the 404 page");
            #     return;
            # }

            # $sth_chat->execute($receiver_user_id, $user_id);

            
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("chat", $my_username, $receiver_username));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the chat page");

        } elsif ($uri eq "/favicon.ico") {
            my $icon_data = html_pages::get_favicon();
            my $response = HTTP_RESPONSE::GET_OK_200_favicon($icon_data);
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd, "favicon.ico");
        } else {
            my $response = HTTP_RESPONSE::NOT_FOUND_404(html_pages::get_html_page("404"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the 404 page");
        }
    } elsif ($method eq 'POST') {
        if ($uri eq '/set_profile') {
            my ($name) = $req->content =~ m/display_name=([^&]+)/;
            if (!$name) {
                print "Invalid name\n";
                menu_utils::write_log("ERROR", "Socket", "Invalid name");
                return;
            }

            $name = uri_unescape($name);
            $name =~ s/\+/ /g;


            my ($email) = $req->content =~ m/email=([^&]+)/;
            $email = uri_unescape($email);
            $email =~ s/\+/ /g;

            my ($password) = $req->content =~ m/password=([^&]+)/;
            $password = uri_unescape($password);
            $password =~ s/\+/ /g;

            my $password_hash = sha1_base64($password);

            my ($first_name) = $req->content =~ m/firstname=([^&]+)/;
            $first_name = uri_unescape($first_name);
            $first_name =~ s/\+/ /g;

            my ($last_name) = $req->content =~ m/lastname=([^&]+)/;
            $last_name = uri_unescape($last_name);
            $last_name =~ s/\+/ /g;

            # update the user in the database

            $client->{name} = $name;


            my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/chat", "name=$name");
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Profile updated successfully");

        } elsif ($uri eq '/api/auth/login') {
            
            my ($username) = $req->content =~ m/username=([^&]+)/;
            $username = uri_unescape($username);
            $username =~ s/\+/ /g;

            my ($password) = $req->content =~ m/password=([^&]+)/;
            $password = uri_unescape($password);
            $password =~ s/\+/ /g;

            print "Username: $username\n";
            print "Password: $password\n";

            my $password_hash = sha1_base64($password);
            
            $sth_user = $dbh->prepare("SELECT password, user_id FROM users WHERE username = ?");
            $sth_user->execute($username);

            my $authenticate = 0;

            my ($password_db, $user_id) = $sth_user->fetchrow_array();

            print "Password from database: $password_db\n";
            print "Password from userinput: $password_hash\n";

            if($password_db){
                if ($password_db eq $password_hash) {
                    $authenticate = 1;
                } else {
                    print "❌ Invalid credentials\n";
                }
            } else {
                print "❌ User not found\n";
            }

        
            # add login timestamps
            $sth_user = $dbh->prepare("UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE username = ?");
            $sth_user->execute($username);


            ## add the user id to the chat_epoll
            $chat_epoll{$fd} = {
                socket => $client->{socket},
                username => $username,
                user_id => $user_id,
            };
            print "Chat Epoll:: \n";
            print Dumper(%chat_epoll);
            print "\n";

            if ($authenticate) {
                my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/", "username=$username");
                send( $client->{socket}, $response, 0 );
                disconnect_client($fd , "Logged in");
            } else {
                my $response = HTTP_RESPONSE::REDIRECT_303(undef, "/error");
                send( $client->{socket}, $response, 0 );
                disconnect_client($fd , "Invalid credentials");
            }
        } elsif ($uri eq '/api/auth/logout') {
            my $logout_cookies = "username=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
            my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/", $logout_cookies);
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Logged out");
        } elsif ($uri eq '/api/auth/register') {
            # my $login = $user_control->login_check($req->cookie);
            # if ($login) {
            #     my $response = HTTP_RESPONSE::REDIRECT_303(undef, "/");
            #     send( $client->{socket}, $response, 0 );
            #     disconnect_client($fd , "Already logged in");
            #     return;
            # }
            
            my ($display_name) = $req->content =~ m/display_name=([^&]+)/;
            if (!$display_name) {
                print "Invalid display name\n";
                menu_utils::write_log("ERROR", "Socket", "Invalid name");
                return;
            }
            $display_name = uri_unescape($display_name);
            $display_name =~ s/\+/ /g;

            my ($fullname) = $req->content =~ m/fullname=([^&]+)/;
            $fullname = uri_unescape($fullname);
            $fullname =~ s/\+/ /g;
            print "fullname: $fullname\n";

            my ($username) = $req->content =~ m/username=([^&]+)/;
            $username = uri_unescape($username);
            $username =~ s/\+/ /g;

            my ($email) = $req->content =~ m/email=([^&]+)/;
            $email = uri_unescape($email);
            $email =~ s/\+/ /g;

            my ($password) = $req->content =~ m/password=([^&]+)/;
            $password = uri_unescape($password);
            $password =~ s/\+/ /g;

            my $password_hash = sha1_base64($password);

            # Add the user to the database
            $sth_user->execute($username, $password_hash, $email, $display_name, 0);

            

            $client->{username} = $username;

            my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/", "username=$username");
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Profile updated successfully");

        } 
    }
}




sub disconnect_client {
    my ($fd, $message) = @_;
    my $client = $epoll{$fd};

    print "Client $client->{ip}:$client->{port} ÄÄ $fd ÄÄ disconnected.\n";
    system("curl -d 'Client $client->{ip}:$client->{port} ÄÄ $fd ÄÄ disconnected.' 10.31.1.1/epoll_server");
    menu_utils::write_log("INFO", "Socket", "Client disconnected");

    print "Disconnected: $message\n" if $message;

    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_DEL, $fd, EPOLLIN );
    close( $client->{socket} );
    delete $epoll{$fd};
}



main_loop();


sub timestamp {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}