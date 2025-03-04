use strict;
use warnings;
use Socket;
use IO::Epoll;
use Data::Dumper;
use HTTP::Request;
use Digest::SHA qw(sha1_base64);
use JSON;
use Switch;
use Term::ReadKey;

# including libraries
use lib qw(../);
use lib '.';
use handle_requests;
use html_pages;
use HTTP_RESPONSE;
use webSocket_utils;
use menu_utils;

open my $log, '>>', 'server.log' or die "Cannot open log file: $!";
select( ( select($log), $| = 1 )[0] );
print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Client connected\n";

my %epoll;

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
    print $log "2025-02-18 12:30:45 [INFO] [Socket] Server stopped\n";
    print $log "--------------------------------------------\n";
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
        my $key = ReadKey(0);
        ReadMode('normal');
    }
}

main_loop();

sub start_server {
    print "Starting server on port 8080... \n";

    my $epoll_Server = epoll_create(10);
    print $log "2025-02-18 12:30:45 [INFO] [Socket] epoll created\n";

    # Create a TCP server socket
    socket( my $server, AF_INET, SOCK_STREAM, 0 ) or die "socket: $!";
    setsockopt( $server, SOL_SOCKET, SO_REUSEADDR, 1 ) or die "setsockopt: $!";
    bind( $server, sockaddr_in( 8080, INADDR_ANY ) ) or die "bind: $!";
    listen( $server, 5 ) or die "listen: $!";

    # Add the server socket to the epoll object
    epoll_ctl( $epoll_Server, EPOLL_CTL_ADD, fileno($server), EPOLLIN ) >= 0
      or die "Failed to add server socket to epoll: $!\n";

    print $log "2025-02-18 12:30:45 [INFO] [Socket] Server started\n";
    print "WebSocket server started on port 8080...\n";

    # Main loop to accept and handle client connections
    while (1) {
        print "Waiting for new event...\n";
        print $log "2025-02-18 12:30:45 [INFO] [Socket] Waiting for new event\n";
        my $events = epoll_wait( $epoll_Server, 10, -1 );

        print "GOT NEW EVENT\n";
        for my $event (@$events) {

            if ( $event->[0] == fileno $server ) {
                my $client_addr = accept( my $client_socket, $server );
                my ( $client_port, $client_ip ) = sockaddr_in($client_addr);
                my $client_ip_str = inet_ntoa($client_ip);
                print "Client connected from $client_ip_str:$client_port\n";
                print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Client connected from $client_ip_str:$client_port\n";

                epoll_ctl( $epoll_Server, EPOLL_CTL_ADD, fileno $client_socket,
                    EPOLLIN ) >= 0
                  || die "Failed to add client socket to epoll: $!\n";

                # Store socket information
                $epoll{ fileno($client_socket) } = {
                    socket => $client_socket,
                    ip     => $client_ip_str,
                    port   => $client_port,
                    status => "Connected",
                };

            }
            elsif ( $event->[1] & EPOLLIN ) {
                print "Handling client data...\n";
                my $request;
                if ( !$epoll{ $event->[0] }{request} ) {
                    $epoll{ $event->[0] }{request}        = "";
                    $epoll{ $event->[0] }{request_length} = 0;
                    $epoll{ $event->[0] }{content_length} = 0;

                    my $buffer;
                    recv( $epoll{ $event->[0] }{"socket"}, $buffer, 1024, 0 );
                    if ( !$buffer ) {
                        print "No data received from client\n";
                        epoll_ctl( $epoll_Server, EPOLL_CTL_DEL, $event->[0], EPOLLIN )
                          >= 0
                          or die
                          "Failed to remove client socket from epoll: $!\n";
                        close $epoll{ $event->[0] }{"socket"};
                        delete $epoll{ $event->[0] };
                        next;
                    }
                    $request = $buffer;
                    $epoll{ $event->[0] }{request} = $request;
                    my $content_length;
                    if ( $request =~ /Content-Length: (\d+)\r/ ) {
                        $content_length = $1;
                        $epoll{ $event->[0] }{request}{content_length} =
                          $content_length;
                        my ( $header, $body ) = split( /\r\n\r\n/, $request );
                        $epoll{ $event->[0] }{request}{header} = $header;
                        $epoll{ $event->[0] }{request}{body}   = $body;
                    }

                    $epoll{ $event->[0] }{request_length} = length($request);
                }

                my $buffer;

                if (   $epoll{ $event->[0] }{content_length}
                    && $epoll{ $event->[0] }{request_length} <
                    $epoll{ $event->[0] }{content_length} )
                {
                    recv( $epoll{ $event->[0] }{"socket"}, $buffer, 1024, 0 );
                    $epoll{ $event->[0] }{request} .= $buffer;
                    $epoll{ $event->[0] }{request_length} += length($buffer);
                }

                if ( $epoll{ $event->[0] }{request_length} >=
                    $epoll{ $event->[0] }{content_length}
                    || length($buffer) < 1024 )
                {
                    my $client_request = $epoll{ $event->[0] }{request};
                    my $req =
                      HTTP::Request->parse( $epoll{ $event->[0] }{request} );
                    my $method = $req->method;
                    my $uri    = $req->uri;
                    if ( !$method || !$uri ) {
                        next;
                    }
                    print "Request from client: \n$client_request\n";
                    print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Request from client: \n$client_request\n";

                    # Check if the request is a websocket connection
                    if ( defined $req->header('Sec-WebSocket-Key') ) {
                        print "Websocket connection detected, establishing the connection now...\n";
                        print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Websocket connection detected, establishing the connection now...\n";

                        my $response = webSocket_utils::handle_websocket_handshake($client_request);
                        send( $epoll{ $event->[0] }{"socket"}, $response, 0 );
                        print "Websocket connection established.\n";
                        print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Websocket connection established.\n";

                        # Store the client as a WebSocket connection
                        $epoll{ $event->[0] }{is_websocket} = 1;
                        print "Client marked as WebSocket connection.\n";
                        print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Client marked as WebSocket connection.\n";

                    } elsif ( $epoll{ $event->[0] }{is_websocket} ) {
                        print "Websocket connection detected.\n";
                        print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Websocket connection detected.\n";

                        print "TEST\n";

                        while ( $epoll{ $event->[0] }{is_websocket} ) {
                            my $frame;
                            my $bytes = sysread( $epoll{ $event->[0] }{"socket"}, $frame, 1024 );
                            last unless $bytes;    # Exit if client disconnects

                            my $message = webSocket_utils::decode_websocket_frame($frame);

                            # sending pong back to the client
                            if ( $message eq "ping" ) {
                                my $response_frame =
                                webSocket_utils::encode_websocket_frame( 0x1, "pong" );
                                send( $epoll{ $event->[0] }{"socket"}, $response_frame, 0 );
                            }

                            print "Received message: $message\n";
                            print $log "2025-02-18 12:30:45 [INFO] [WebSocket] Received message: $message\n";

                            my $response_frame = webSocket_utils::encode_websocket_frame( 0x1, $message );
                            send( $epoll{ $event->[0] }{"socket"}, $response_frame, 0 )
                            unless $message eq "ping";
                            }

                    }
                    else {
                        print "No websocket connection detected.\n";
                        print $log "2025-02-18 12:30:45 [INFO] [WebSocket] No websocket connection detected.\n";

                        handle_client_data( $event, $epoll );
                    }

                    
                }
                else {
                    print "Unknown event: $event->[1]\n";
                }
            }
        }

    }

    sub handle_client_data {
        my ( $event, $epoll ) = @_;
        my $client_request = $epoll{ $event->[0] }{request};
        my $req    = HTTP::Request->parse( $epoll{ $event->[0] }{request} );
        my $method = $req->method;
        my $uri    = $req->uri;
        if ( !$method || !$uri ) {
            return;
        }


        if ( $method eq 'GET' ) {
            if ( $uri eq '/' ) {

                my $response =
                  HTTP_RESPONSE::GET_OK_200(
                    html_pages::get_html_page("index") );
                send( $epoll{ $event->[0] }{"socket"}, $response, 0 );
                epoll_ctl( $epoll_Server, EPOLL_CTL_DEL, $event->[0], EPOLLIN ) >= 0
                  or die "Failed to remove client socket from epoll: $!\n";
                close $epoll{ $event->[0] }{"socket"};
                delete $epoll{ $event->[0] };
                print "Response sent to client\n";

            }
            elsif ( $uri eq "/chat" ) {

                my $response =
                  HTTP_RESPONSE::GET_OK_200(
                    html_pages::get_html_page("chat") );
                send( $epoll{ $event->[0] }{"socket"}, $response, 0 );
                epoll_ctl( $epoll_Server, EPOLL_CTL_DEL, $event->[0], EPOLLIN ) >= 0
                  or die "Failed to remove client socket from epoll: $!\n";
                close $epoll{ $event->[0] }{"socket"};
                delete $epoll{ $event->[0] };
                print "Response sent to client\n";

            }
        }
    }

}

