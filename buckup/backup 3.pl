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

# Including libraries
use lib qw(../);
use lib '.';
use handle_requests;
use html_pages;
use HTTP_RESPONSE;
use webSocket_utils;
use menu_utils;

open my $log, '>>', 'server.log' or die "Cannot open log file: $!";
select( ( select($log), $| = 1 )[0] );

my %epoll;
my %chat_epoll;

sub show_menu {
    system("clear");
    print "======= WebSocket Server =======\n";
    print "1. Start server\n";
    print "2. Stop server\n";
    print "3. Show log\n";
    print "0. Exit\n";
    print "================================\n";
}

sub stop_server {
    print "Stopping server...\n";
    write_log("INFO", "Socket", "Server stopped");
    close $log;
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
    write_log("INFO", "Socket", "starting server on port 8080...");

    $epoll{server_epoll} = epoll_create(10);
    write_log("INFO", "Socket", "epoll created");

    # Create a TCP server socket
    socket( my $server, AF_INET, SOCK_STREAM, 0 ) or die "socket: $!" && write_log("ERROR", "Socket", "socket: $!");
    setsockopt( $server, SOL_SOCKET, SO_REUSEADDR, 1 ) or die "setsockopt: $!" && write_log("ERROR", "Socket", "setsockopt: $!");
    bind( $server, sockaddr_in( 8080, INADDR_ANY ) ) or die "bind: $!" && write_log("ERROR", "Socket", "bind: $!");
    listen( $server, 5 ) or die "listen: $!" && write_log("ERROR", "Socket", "listen: $!");

    # Add the server socket to epoll
    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_ADD, fileno($server), EPOLLIN ) >= 0
      or die "Failed to add server socket to epoll: $!\n" && write_log("ERROR", "Socket", "Failed to add server socket to epoll: $!\n");

    print "WebSocket server started on port 8080...\n";
    write_log("INFO", "Socket", "Server started");

    # Main loop to handle events
    while (1) {
        my $events = epoll_wait( $epoll{server_epoll}, 10, -1 );

        for my $event (@$events) {
            if ( $event->[0] == fileno $server ) {
                my $client_addr = accept( my $client_socket, $server );
                my ( $client_port, $client_ip ) = sockaddr_in($client_addr);
                my $client_ip_str = inet_ntoa($client_ip);
                print "Client connected from $client_ip_str:$client_port\n";
                write_log("INFO", "Socket", "Client connected from $client_ip_str:$client_port");

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
}

sub handle_client {
    my ($fd) = @_;
    my $client = $epoll{$fd};
    my $buffer;
    
    my $bytes_read = sysread( $client->{socket}, $buffer, 1024);

    if (!$bytes_read) {
        print "OH NOW THE CLIENT DISCONNECTED\n";
        disconnect_client($fd);
        return;
    }

    if ($client->{is_websocket}) {
        handle_websocket_message($fd, $buffer);
    } else {
        handle_http_request($fd, $buffer);
    }
}

sub handle_http_request {
    my ($fd, $buffer) = @_;
    my $client = $epoll{$fd};

    my $req = HTTP::Request->parse($buffer);
    if (!$req) {
        print "Invalid HTTP req\n";
        write_log("ERROR", "Socket", "Invalid HTTP request");
        return;
    }

    my $method = $req->method;
    my $uri    = $req->uri;

    # Handle WebSocket Upgrade
    if ( defined $req->header('Sec-WebSocket-Key') ) {
        my $response = webSocket_utils::handle_websocket_handshake($buffer);
        send( $client->{socket}, $response, 0 );
        $client->{is_websocket} = 1;
        write_log("INFO", "Socket", "WebSocket connection established");
        write_log("INFO", "Socket", "Client marked as WebSocket");

        # Store client information in the chat_epoll
        $chat_epoll{$fd} = $client->{socket};

        print "Chat epoll: \n" . Dumper(\%chat_epoll) . "\n";

        return;
    }

    # Handle normal HTTP requests
    if ($method eq 'GET') {
        if ($uri eq '/test') {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("index"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        } elsif ($uri eq "/chat") {
            # check the cookies
            my $cookie = $req->header('Cookie') ;
            my $name = menu_utils::get_cookie_value($cookie, "name");
            if ($cookie =~ /name=(.*)/) {
                my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("chat" , $1));
                send( $client->{socket}, $response, 0 );
            } else {
                my $response = HTTP_RESPONSE::REDIRECT_303(undef, "/profile");
                send( $client->{socket}, $response, 0 );
            }
            disconnect_client($fd);
        } elsif ($uri eq "/") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("menu"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        
        } elsif ($uri eq "/profile") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("profile"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);

        } elsif ($uri eq "/error") {
            my $response = HTTP_RESPONSE::GET_OK_200(html_pages::get_html_page("error"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        
        } elsif ($uri eq "/favicon.ico") {
            my $icon_data = html_pages::get_favicon();
            my $response = HTTP_RESPONSE::GET_OK_200_favicon($icon_data);
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        } else {
            my $response = HTTP_RESPONSE::NOT_FOUND_404(html_pages::get_html_page("404"));
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        }
    } elsif ($method eq 'POST') {
        if ($uri eq '/set_profile') {
            my ($name) = $req->content =~ m/display_name=([^&]+)/;
            if (!$name) {
                print "Invalid name\n";
                write_log("ERROR", "Socket", "Invalid name");
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



            print "/////////////////////////////////////////\n";
            print "Body: \n";
            print $req->content;
            print "/////////////////////////////////////////\n";
            

            print "Name: $name\n";
            write_log("INFO", "Socket", "Name: $name");

             # Initialize $users as an empty array
            my $users = [];

            open my $fh, '<', "users.json" or die $!;
            local $/ = undef;
            my $json_data = <$fh>;
            if ($json_data) {
                $users = decode_json($json_data);
            }
            close $fh;

            # Check if username already exists
            foreach my $user (@$users) {
                if ($user->{display_name} eq $name) {
                    print "User already exists!\n";
                    
                    my $response = HTTP_RESPONSE::REDIRECT_303(undef, "/error");
                    send( $client->{socket}, $response, 0 );
                    disconnect_client($fd);
                    return;
                }
            }

            push @$users, {
                first_name => $first_name,
                last_name => $last_name,
                email => $email,
                password => $password_hash,
                display_name => $name
            };

            # Save the profile details to a file
            if (open my $fh, '>' , "users.json") {
                print $fh encode_json($users);
                close $fh;
                print "Profile updated successfully!\n";
                write_log("INFO", "Socket", "Profile updated successfully");
            } else {
                print "Could not open file for writing: $!\n";
                write_log("ERROR", "Socket", "Could not open file for writing: $!\n");
            }

            $client->{name} = $name;


            my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/chat", "name=$name");
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        } elsif ($uri eq '/logout') {
            my $logout_cookies = "name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
            my $response = HTTP_RESPONSE::REDIRECT_303_with_cookie(undef, "/profile", $logout_cookies);
            send( $client->{socket}, $response, 0 );
            disconnect_client($fd);
        }
    }
}



sub handle_websocket_message {
    my ($fd, $frame) = @_;
    my $client = $epoll{$fd};

    my $message = webSocket_utils::decode_websocket_frame($frame);
    if ($message eq "ping") {
        my $response_frame = webSocket_utils::encode_websocket_frame( 0x1, "pong" );
        send( $client->{socket}, $response_frame, 0 );
        return;
    }


    # Broadcast the message to all clients except the sender
    foreach my $broadcast_fd (keys %chat_epoll) {
        if ($broadcast_fd != $fd) {
            my $broadcast_client = $epoll{$broadcast_fd};
            if (!$broadcast_client->{socket}) {
                print "Client $broadcast_fd not found\n";
                next;
            }
            my $response_frame = webSocket_utils::encode_websocket_frame( 0x1, $message );
            print "test 1: $broadcast_client->{socket}\n";
            print "test 2: $response_frame\n";
            send( $broadcast_client->{socket}, $response_frame, 0 ) or die "Failed to send message to client: $!\n";
        }
    }

    print "Received message: $message\n";
    write_log("INFO", "Socket", "Received message from $client->{ip}:$client->{port}: $message\n");
    send( $client->{socket}, $message, 0 );


    # my $response_frame = webSocket_utils::encode_websocket_frame( 0x1, $message );
    # send( $client->{socket}, $response_frame, 0 );
}

sub disconnect_client {
    my ($fd) = @_;
    my $client = $epoll{$fd};

    print "Client $client->{ip}:$client->{port} ÄÄ $fd ÄÄ disconnected.\n";
    write_log("INFO", "Socket", "Client disconnected");

    epoll_ctl( $epoll{server_epoll}, EPOLL_CTL_DEL, $fd, EPOLLIN );
    close( $client->{socket} );
    delete $epoll{$fd};
}

sub write_log {
    my ($type, $from , $message ) = @_;
    $type = uc($type);
    my $time = localtime;
    print $log "$time - [$type] [$from] $message\n";
}

main_loop();
