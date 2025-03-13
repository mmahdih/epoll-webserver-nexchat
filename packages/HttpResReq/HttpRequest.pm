package HttpRequest;

use strict;
use warnings;
use JSON;
use Data::Dumper;


sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{_method} = $args{method};
    $self->{_uri} = $args{uri};
    $self->{_headers} = $args{headers};
    $self->{_body} = $args{body};
    return $self;
}


sub parse {
    my ($class, $request) = @_;
    print "request: $request\n";

    # Split request into method line, headers, and body
    my ($method_line, $header_block, $body) = split("\r\n\r\n", $request, 3);
    $body //= '';  # Ensure body is at least an empty string if undefined

    # Extract method and URI
    my ($method, $uri) = (split(" ", $method_line))[0, 1];
    print "method: $method\n";
    print "uri: $uri\n";

    # Parse headers
    # my @headers = split("\r\n", $header_block);
    # my %head;
    # foreach my $header (@headers) {
    #     if ($header =~ /^([^:]+):\s*(.*)$/) {  # More robust regex matching
    #         my ($key, $value) = ($1, $2);
    #         $head{$key} = $value;
    #     }
    # }

    my %head;
    foreach my $header (split("\r\n", $header_block)) {
        if ($header =~ /^([^:]+):\s*(.*)$/) {  # More robust regex matching
            my ($key, $value) = ($1, $2);
            $head{$key} = $value;
        }
    }
    print Dumper(\%head);

    return $class->new(method => $method, uri => $uri, headers => \%head, body => $body);
}



sub method {
    my ($self) = @_;
    return $self->{_method};
}


sub uri {
    my ($self) = @_;
    return $self->{_uri};
}


sub headers {
    my ($self) = @_;
    return $self->{_headers};
}   


sub body {
    my ($self) = @_;
    return $self->{_body};
}


sub to_string {
    my ($self) = @_;
    my $json = encode_json({method => $self->{_method}, uri => $self->{_uri}, headers => $self->{_headers}, body => $self->{_body}});
    return $json;
}   





1;