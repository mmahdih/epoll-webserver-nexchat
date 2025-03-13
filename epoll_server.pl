
use strict;
use warnings;
use IO::Epoll;
use Socket;
use JSON;

# Including libraries
use lib '.';  
use includes;

my $port = 8080;


## Connect to PostgreSQL database
my $dbh;
DatabaseUtils::connect_to_database();
$dbh = $DatabaseUtils::dbh;
if (!$dbh) {
    print "Failed to connect to database\n";
    exit;
}


my %epoll;
my %chat_epoll;

# Smtp server object
my $smtp_server = smtp_server->new();

# User control object
my $UserControl = UserControl->new();

# WebSocket server object
my $websocket_server = WebSocketUtils->new();

# HTTP server object
my $HttpRequest = HttpRequest->new();


my $hehe;

sub start_smtp_server {
    $smtp_server->start();
}



# start smtp server
includes::GetOptions(
    'start' => \&start_server,
    'port=i' => \$port,
    'smtp' => \&start_smtp_server,
    'help' => \&help,
    'test' => \&test
) or die "Error in command line arguments\n";






# Routes
my %get_routes = (
    '/'                 => \&home_page,
    '/chat'             => \&profile_page,
    '/favicon'          => \&settings_page,
    '/settings'         => \&dashboard_page,  # New GET route
    '/settings/profile' => \&help_page,       # New GET route
);

my %post_routes = (
    '/api/auth/login'       => \&login_handler,
    '/api/auth/register'    => \&register_handler,
    '/api/auth/logout'      => \&update_handler,
    '/delete'               => \&delete_handler,   # New POST route
);

my %websocket_routes = (
    '/notifications' => \&notifications_handler,
    '/chatroom'      => \&chatroom_handler,  # New WebSocket route
);

my $sth_user;
my $sth_chat;
my $sth_message;



sub start_server {
    print "Starting server on port $port... \n";

    $epoll{server_epoll} = epoll_create(10);

    # Create a TCP server socket
    socket( my $server, AF_INET, SOCK_STREAM, 0 ) 
        or die "socket: $!" && MenuUtils::write_log("ERROR", "Socket", "socket: $!");

    setsockopt( $server, SOL_SOCKET, SO_REUSEADDR, 1 ) 
        or die "setsockopt: $!" && MenuUtils::write_log("ERROR", "Socket", "setsockopt: $!");

    bind( $server, sockaddr_in( $port, INADDR_ANY ) ) 
        or die "bind: $!" && MenuUtils::write_log("ERROR", "Socket", "bind: $!");

    listen( $server, 5 ) 
        or die "listen: $!" && MenuUtils::write_log("ERROR", "Socket", "listen: $!");


    # connect to database
    DatabaseUtils::connect_to_database();
    
    # Create table if not exists
    DatabaseUtils::create_tables();
    
    # Prepare insert statement
    my $sth_user = $dbh->prepare(q{INSERT INTO users (username, password, email, display_name, is_admin) VALUES (?, ?, ?, ?, ?) RETURNING user_id})
        or die "Prepare statement failed: $dbh->errstr()";
    my $sth_chat = $dbh->prepare(q{INSERT INTO chats (chat_name, is_group) VALUES (?, ?)})
        or die "Prepare statement failed: $dbh->errstr()";



    # Add the server socket to epoll
    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_ADD, fileno($server), EPOLLIN ) >= 0
      or die "Failed to add server socket to epoll: $!\n" && MenuUtils::write_log("ERROR", "Socket", "Failed to add server socket to epoll: $!\n");

    print "WebSocket server started on port $port...\n";
    MenuUtils::write_log("INFO", "Socket", "Server started");

    # Main loop to handle events
    while (1) {
        my $events = epoll_wait( $epoll{server_epoll}, 10, -1 );

        for my $event (@$events) {
            if ( $event->[0] == fileno $server ) {
                my $client_addr = accept( my $client_socket, $server );
                my ( $client_port, $client_ip ) = sockaddr_in($client_addr);
                my $client_ip_str = inet_ntoa($client_ip);
                print "Client connected from $client_ip_str:$client_port\n";

                MenuUtils::write_log("INFO", "Socket", "Client connected from $client_ip_str:$client_port");

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
        $websocket_server->handle_websocket_message($fd, $buffer, \%epoll, \%chat_epoll, $hehe, $dbh);
    } else {
        handle_HttpRequest($fd, $buffer);
    }
}

sub handle_HttpRequest {
    my ($fd, $buffer) = @_;
    my $client = $epoll{$fd};

    my $req = HTTP::Request->parse($buffer);
    $hehe = $req->uri;
    if (!$req) {
        print "Invalid HTTP req\n";
        MenuUtils::write_log("ERROR", "Socket", "Invalid HTTP request");
        return;
    }
    # print "test\n";
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
        print "Chat epoll: \n" . includes::Dumper(\%chat_epoll) . "\n";

        return;
    }

    # Handle normal HTTP requests
    if ($method eq 'GET') {
        if ($uri eq "/chat") {
            # check the cookies
            my $cookie = $req->header('Cookie') ;
            my $username = MenuUtils::get_cookie_value($cookie, "username");
            print "Cookie: $cookie, username: $username\n";
            if ($cookie =~ /username=(.*)/) {
                my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("chat" , $1));
                send( $client->{socket}, $response, 0 );
            } else {
                my $response = HttpResponse::REDIRECT_303(undef, "/login");
                send( $client->{socket}, $response, 0 );
            }
            disconnect_client($fd , "this is the chat page");
        } elsif ($uri eq "/") {
            my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("home"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the menu page");
        
        } elsif ($uri eq "/profile") {
            my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("profile"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the profile page");

        } elsif ($uri eq "/login") {
            my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("login"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the login page");

        } elsif ($uri eq "/register") {
            my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("register"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the register page");

        } elsif ($uri eq "/error") {
            my $response = HttpResponse::GET_OK_200(HtmlPages::get_html_page("error"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the error page");
        } elsif ($uri eq "/favicon.ico") {
            my $icon_data = HtmlPages::get_favicon();
            my $response = HttpResponse::GET_OK_200_favicon($icon_data);
            send( $client->{socket}, $response, 0 );
            # disconnect_client($fd, "favicon.ico");
        } else {
            my $response = HttpResponse::NOT_FOUND_404(HtmlPages::get_html_page("404"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "this is the 404 page");
        }
    } elsif ($method eq 'POST') {
        if ($uri eq '/set_profile') {
            my ($name) = $req->content =~ m/display_name=([^&]+)/;
            if (!$name) {
                print "Invalid name\n";
                MenuUtils::write_log("ERROR", "Socket", "Invalid name");
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


            my $response = HttpResponse::REDIRECT_303_with_cookie(undef, "/chat", "name=$name");
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Profile updated successfully");

        } elsif ($uri eq '/api/auth/login') {
            
            my ($username) = $req->content =~ m/username=([^&]+)/;
            $username = includes::uri_unescape($username);
            $username =~ s/\+/ /g;

            my ($password) = $req->content =~ m/password=([^&]+)/;
            $password = includes::uri_unescape($password);
            $password =~ s/\+/ /g;

            print "Username: $username\n";
            print "Password: $password\n";

            my $password_hash = includes::sha1_base64($password);
            
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

            $epoll{$fd}{user_id} = $user_id;
            print "Chat Epoll:: \n";
            print includes::Dumper(%chat_epoll);
            print "\n";

            if ($authenticate) {
                my $response = HttpResponse::REDIRECT_303_with_cookie(undef, "/", "username=$username");
                send( $client->{socket}, $response, 0 );
                disconnect_client($fd , "Logged in");
            } else {
                my $response = HttpResponse::REDIRECT_303(undef, "/error");
                send( $client->{socket}, $response, 0 );
                disconnect_client($fd , "Invalid credentials");
            }
        } elsif ($uri eq '/api/auth/logout') {
            my $logout_cookies = "username=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
            my $response = HttpResponse::REDIRECT_303_with_cookie(undef, "/", $logout_cookies);
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Logged out");
        } elsif ($uri eq '/api/auth/register') {
            # my $login = $UserControl->login_check($req->cookie);
            # if ($login) {
            #     my $response = HttpResponse::REDIRECT_303(undef, "/");
            #     send( $client->{socket}, $response, 0 );
            #     disconnect_client($fd , "Already logged in");
            #     return;
            # }
            
            my ($display_name) = $req->content =~ m/display_name=([^&]+)/;
            if (!$display_name) {
                print "Invalid display name\n";
                # MenuUtils::write_log("ERROR", "Socket", "Invalid name");
                return;
            }
            $display_name = includes::uri_unescape($display_name);
            $display_name =~ s/\+/ /g;

            my ($fullname) = $req->content =~ m/fullname=([^&]+)/;
            $fullname = includes::uri_unescape($fullname);
            $fullname =~ s/\+/ /g;
            print "fullname: $fullname\n";

            my ($username) = $req->content =~ m/username=([^&]+)/;
            $username = includes::uri_unescape($username);
            $username =~ s/\+/ /g;

            my ($email) = $req->content =~ m/email=([^&]+)/;
            $email = includes::uri_unescape($email);
            $email =~ s/\+/ /g;

            my ($password) = $req->content =~ m/password=([^&]+)/;
            $password = includes::uri_unescape($password);
            $password =~ s/\+/ /g;

            my $password_hash = includes::sha1_base64($password);

            # Add the user to the database
            $sth_user->execute($username, $password_hash, $email, $display_name, 0);

            my $user_id = $sth_user->fetchall_arrayref({})->[0]->{chat_id};
            print "User ID: $user_id\n";

            # add the user id to the chat_epoll
            $chat_epoll{$fd} = {
                socket => $client->{socket},
                username => $username,
                user_id => $user_id,
            };
            

            $client->{username} = $username;

            my $response = HttpResponse::REDIRECT_303_with_cookie(undef, "/", "username=$username");
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd , "Profile updated successfully");

        } 
    }
}


sub disconnect_client {
    my ($fd, $message) = @_;
    my $client = $epoll{$fd};

    print "Client $client->{ip}:$client->{port} $fd disconnected.\n";
    print "Disconnected: $message\n" if $message;

    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_DEL, $fd, EPOLLIN );
    close( $client->{socket} );
    delete $epoll{$fd};
}


sub help {
    print "Usage: perl epoll_server.pl [options]\n";
    print "Options:\n";
    print "  --start     Start the server\n";
    print "  --port      Specify the port number\n";
    print "  --smtp      Start the SMTP server\n";
}

