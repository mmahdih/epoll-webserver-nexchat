package WebSocketUtils;


sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{_fin} = $args{fin} || 1;
    $self->{_mask} = $args{mask} || 0;
    return $self;
}

sub handle_websocket_handshake {
    my ($self, $client_request) = @_;
    
    if (!$client_request) {
        die "handle_websocket_handshake requires a client request";
    }
    # print "client requestttttt: $client_request\n";
    my $key;
    if ($client_request =~ /Sec-WebSocket-Key: (.*?)\r/) {
        $key = $1;
    }
    my $accept_key = $key . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    # $accept_key = Digest::SHA::sha1_base64($accept_key) . "=";
    $accept_key = includes::encode_base64(Digest::SHA::sha1($accept_key), '');

    my $response = "HTTP/1.1 101 Switching Protocols\r\n";
    $response .= "Upgrade: websocket\r\n";
    $response .= "Connection: Upgrade\r\n";
    $response .= "Sec-WebSocket-Accept: $accept_key\r\n";
    $response .= "\r\n";

    return $response;
}

sub decode_websocket_frame {
    my ($self, $frame) = @_;
    return "" if length($frame) < 2;  # Minimum frame size check

    my $first_byte  = ord(substr($frame, 0, 1));
    my $second_byte = ord(substr($frame, 1, 1));

    my $fin  = ($first_byte >> 7) & 1;   # Check FIN bit (should be 1 for final message)
    my $opcode = $first_byte & 0x0F;     # Get Opcode (0x1 = text frame)

    my $masked = ($second_byte >> 7) & 1;  # Check if data is masked
    my $payload_len = $second_byte & 0x7F; # Get Payload Length

    my $offset = 2; # Start after first two bytes

    # Handle extended payload lengths
    if ($payload_len == 126) {
        $payload_len = unpack("n", substr($frame, 2, 2));  # Read next 2 bytes
        $offset += 2;
    } elsif ($payload_len == 127) {
        $payload_len = unpack("Q>", substr($frame, 2, 8)); # Read next 8 bytes
        $offset += 8;
    }

    # Read masking key (if masked)
    my $masking_key = "";
    if ($masked) {
        $masking_key = substr($frame, $offset, 4);
        $offset += 4;
    }

    # Extract the payload data
    my $payload = substr($frame, $offset, $payload_len);

    # Unmask the payload (if masked)
    if ($masked) {
        my @mask_bytes = unpack("C4", $masking_key);
        for my $i (0 .. length($payload) - 1) {
            substr($payload, $i, 1) = chr(ord(substr($payload, $i, 1)) ^ $mask_bytes[$i % 4]);
        }
    }

    return $payload;
}

sub encode_websocket_frame {
    my ($self, $opcode, $payload) = @_;
    my $fin = $self->{_fin};  # Set to 1 for final frame
    my $mask = $self->{_mask}; # No masking for server-to-client

    my $payload_len = length($payload);
    my $frame = pack("C", ($fin << 7) | $opcode);  # FIN + Opcode

    if ($payload_len <= 125) {
        $frame .= pack("C", $payload_len);  # 1-byte payload length
    } elsif ($payload_len <= 65535) {
        $frame .= pack("C", 126) . pack("n", $payload_len);  # 2-byte extended length
    } else {
        $frame .= pack("C", 127) . pack("Q>", $payload_len);  # 8-byte extended length
    }

    if ($mask) {
        my @mask_bytes = unpack("C4", pack("H*", "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"));
        for my $i (0 .. length($payload) - 1) {
            substr($frame, $i, 1) = chr(ord(substr($payload, $i, 1)) ^ $mask_bytes[$i % 4]);
        }
    } else {
        $frame .= $payload;
    }

    return $frame;
}


sub form_pong_frame {
    my ($self, $payload) = @_;

    my $fin_opcode = 0x8A;  # FIN + Pong opcode
    my $payload_len = length($payload);

    # Form the frame
    my $frame = pack('C', $fin_opcode);  # 1st byte: FIN + Pong
    if ($payload_len <= 125) {
        $frame .= pack('C', $payload_len);  # 2nd byte: Payload length
    } elsif ($payload_len <= 65535) {
        $frame .= pack('C', 126)  # 2nd byte: Extended payload length indicator
               . pack('n', $payload_len);  # 2 bytes: Payload length
    } else {
        $frame .= pack('C', 127)  # 2nd byte: Extended payload length indicator
               . pack('Q>', $payload_len);  # 8 bytes: Payload length
    }

    $frame .= $payload;  # Add the payload data

    return $frame;
}

sub form_close_frame {
    my ($self) = @_;
    my $frame = pack('CC', 0x88, 0x00);
    return $frame;
}

sub form_text_frame {
    my ($self, $payload) = @_;

    # Set FIN=1 (final frame) and opcode=0x1 (text frame)
    my $frame = pack("C", 0b10000001);  # FIN=1, opcode=0x1

    # Determine the payload length
    my $length = length($payload);

    if ($length < 126) {
        $frame .= pack("C", $length);  # 1-byte payload length
    } elsif ($length <= 65535) {
        $frame .= pack("C", 126) . pack("n", $length);  # 2-byte extended length
    } else {
        $frame .= pack("C", 127) . pack("Q>", $length);  # 8-byte extended length
    }

    # Append the masking key and masked payload
    $frame .= $payload;

    return $frame;
}

sub form_control_frame {
    my ($self, $opcode, $payload) = @_;
    my $fin = $self->{_fin};  # Set to 1 for final frame
    my $mask = $self->{_mask}; # No masking for server-to-client

    # Construct the first byte: FIN + Opcode
    my $first_byte = ($fin << 7) | ($opcode & 0x0F);

    # Determine payload length
    my $payload_length = length($payload);
    die "Control frame payload too large" if $payload_length > 125;  # Control frames max 125 bytes

    # Construct the second byte: Mask + Payload length
    my $second_byte = ($mask << 7) | $payload_length;

    # Combine frame
    return pack('C*', $first_byte, $second_byte) . $payload;
}


sub binary_to_ascii {
    my ($self, $binary) = @_;
    my $ascii = unpack('H*', $binary);
    return $ascii;
}


sub hex_to_ascii {
    my ($self, $hex) = @_;
    my $ascii = pack('H*', $hex);
    return $ascii;
}

sub handle_websocket_message {
    my ($self, $fd, $frame, $epoll_ref, $chat_epoll_ref, $uri, $dbh) = @_;

    my $client = $epoll_ref->{$fd};
    if (!$client) {
        print "Client not found in epoll\n";
        return;
    }
    my $message;
    my $received = $self->decode_websocket_frame($frame);
    if (!$frame) {
        print "Failed to decode websocket frame\n";
        return;
    }
    
    # print "REseived: $received\n";
    if (!$received) {
        print "Failed to decode websocket frame\n";
        return;
    } else {
        $message = "";
        eval {
            $message = JSON::decode_json($received);
        };
        if ($@) {
            print "Error decoding JSON: $@\n";
            # You can also return or handle the error here
        }
    }

    # print "Received message: " . includes::Dumper($message) . "\n";

    
    if ($message->{action} ne "ping") {
        print "Received message: " . includes::Dumper($message) . "\n";
    }

    # Send a pong back to a ping message
    if ($message->{action} eq "ping") {
        my $res = {
            action => "pong"
        };
        my $response_frame = $self->encode_websocket_frame( 0x1, includes::encode_json($res) );
        send( $client->{socket}, $response_frame, 0 );
    }

        if ( $message->{action} eq 'get_users') {
            # get all users from the users table in the database
            my $sth = $dbh->prepare('SELECT user_id, username, display_name FROM users');
            $sth->execute();
            my $users = $sth->fetchall_arrayref({});
            $sth->finish();
            print "Users: " . includes::Dumper($users);
        
            my $res = {
                action => "users_list",
                users => $users
            };


            my $response_frame = $self->encode_websocket_frame(0x1, JSON::to_json($res));
            send($client->{socket}, $response_frame, 0);
            # return;
        } elsif ($message->{action} eq 'send_message') {

            # get the message details from json message
            my $chat_id = $message->{chat_id};
            my $content = $message->{message};
            my $sender_username = $message->{sender_username};
            my $sender_id = $self->get_user_id_by_username($sender_username, $dbh);


            die "Error: Sender ID not found" unless defined $sender_id;


            print "test chat id : $chat_id\n";
            print "test message : $content\n";

            $sth = $dbh->prepare('
                                    INSERT INTO messages (chat_id, senderid, content)
                                    VALUES (?,?,?)
                                    ');
            $sth->execute($chat_id, $sender_id, $content);
            print "message saved to the database\n";
            

        } elsif ($message->{action} eq 'get_chat_id') {
            print "user asks for chat id\n";

            # get the receiver_id from json message
            my $receiver_id = $message->{receiver_id}; 
            my $sender_username = $message->{sender_username};
            my $sender_id = $self->get_user_id_by_username($sender_username, $dbh);


            die "Error: Sender ID not found" unless defined $sender_id;

            print includes::Dumper($message);   
           
            my $chat_id = $self->get_chat_id($dbh, $sender_id, $receiver_id);


            if (!$chat_id) {
                # create a new chat
                $sth = $dbh->prepare('  INSERT INTO chats (is_group, created_at) 
                                        VALUES (false, NOW()) 
                                        RETURNING chat_id
                                        ;
                                    ');
                $sth->execute() or die "Insert failed: $dbh->errstr()";
                my ($chat_id) = $sth->fetchrow_array();
                $sth->finish();
                print "Chat ID: " . $chat_id . "\n";
                $sth = $dbh->prepare('
                                        INSERT INTO chat_participants (chat_id, user_id) 
                                        VALUES (?, ?), (?, ?)
                                        
                                        ;
                                    ');
                print "Chat ID: " . $chat_id . "\n";
                print "User ID: " . $sender_id . "\n";
                print "Receiver ID: " . $receiver_id . "\n";

                $sth->execute($chat_id, $sender_id, $chat_id, $receiver_id) or die "Insert failed: $dbh->errstr()";
                $sth->finish();

            }
            print "Chat ID: " . $chat_id . "\n";

            my $res = {
                action => "chat_id",
                chat_id => $chat_id
            };

            my $response_frame = $self->encode_websocket_frame(0x1, JSON::to_json($res));
            send($client->{socket}, $response_frame, 0);
        } elsif ($message->{action} eq 'get_messages') {

            my $chat_id = $message->{chat_id};
            my $sth = $dbh->prepare('
                                        SELECT senderid, content
                                        FROM messages
                                        WHERE chat_id = ?
                                    ');
            $sth->execute($chat_id) or die "Select failed: $dbh->errstr()";
            my $messages = $sth->fetchall_arrayref({});
            $sth->finish();
            # print "Messages: " . Dumper($messages) . "\n";
            
            my $user_messages = [];
            foreach my $message (@$messages) {
                print "Sender ID: " . $message->{senderid} . "\n";
                $sth = $dbh->prepare('
                                        SELECT username
                                        FROM users
                                        WHERE user_id = ?
                                    ');
                $sth->execute($message->{senderid}) or die "Select failed: $dbh->errstr()";
                my $sender_username = $sth->fetchrow_hashref();
                $sth->finish();

                push @$user_messages, {
                    sender_username => $sender_username->{username},
                    content => $message->{content}
                };
                
            }

           

            my $res = {
                action => "messages",
                messages => $user_messages
            };

            my $response_frame = $self->encode_websocket_frame(0x1, JSON::to_json($res));
            send($client->{socket}, $response_frame, 0);
        }
    # }
}





    # Broadcast the message to all clients except the sender
    # foreach my $broadcast_fd (keys %chat_epoll) {
    #     if ($broadcast_fd != $fd) {
    #         my $broadcast_client = $epoll{$broadcast_fd};
    #         if (!$broadcast_client->{socket}) {
    #             print "Client $broadcast_fd not found\n";
    #             next;
    #         }
    #         my $response_frame = $self->encode_websocket_frame( 0x1, $message );
    #         send( $broadcast_client->{socket}, $response_frame, 0 ) or die "Failed to send message to client: $!\n";
    #     }
    # }



sub upgrade_to_websocket {
    my ($self, $fd, $buffer, %epoll) = @_;
    my $client = $epoll{$fd};
    print "Upgrading to WebSocket\n";
    print "Client request: $buffer\n";
# Upgrades a client to a WebSocket connection.
#
# Args:
#   $fd - The file descriptor of the client.
#   $buffer - The client's request.
#   %epoll - The epoll hash containing all connected clients.
#
# Side Effects:
#   The client is marked as a WebSocket client and its request is responded to.

    my $response = $self->handle_websocket_handshake($buffer);
    send( $client->{socket}, $response, 0 );
    $client->{is_websocket} = 1;

}

sub get_username_by_id {
    my ($self, $user_id, $dbh) = @_;
    my $sth = $dbh->prepare('SELECT username FROM users WHERE user_id = ?');
    $sth->execute($user_id) or die "Select failed: $dbh->errstr()";
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    return $row ? $row->{username} : undef;
}

sub get_user_id_by_username {
    my ($self, $username, $dbh) = @_;
    my $sth = $dbh->prepare('SELECT user_id FROM users WHERE username = ?');
    $sth->execute($username) or die "Select failed: $dbh->errstr()";
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    return $row ? $row->{user_id} : undef;
}


sub get_chat_id {
    my ($self, $dbh, $sender_id, $receiver_id) = @_;
    my $sth = $dbh->prepare('SELECT chat_id FROM chat_participants WHERE user_id = ? AND chat_id IN (SELECT chat_id FROM chat_participants WHERE user_id = ?)');
    $sth->execute($sender_id, $receiver_id) or die "Select failed: " . $dbh->errstr;
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    return $row ? $row->{chat_id} : undef;
}


1;
