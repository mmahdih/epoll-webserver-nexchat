package HttpResponse;

use strict;
use warnings;

sub REDIRECT_303 {
    my ($data, $path) = @_;

    my $response;
    $response .= "HTTP/1.1 303 See Other\r\n";
    $response .= "Location: $path\r\n";
    $response .= "\r\n";
    # $response .= $data;

    return $response;
}

sub REDIRECT_303_with_cookie {
    my ($data, $path, $cookie) = @_;
    
    my $response;
    $response .= "HTTP/1.1 303 See Other\r\n";
    $response .= "Location: $path\r\n";
    $response .= "Set-Cookie: $cookie; Path=/\r\n"; 
    $response .= "\r\n";
    $response .= $data;

print "response: $response\n";
    return $response;
}

sub REDIRECT_303_with_Error {
    my ($data, $path, $error) = @_;

    my $response;
    $response .= "HTTP/1.1 303 See Other\r\n";
    $response .= "Location: $path\r\n";
    $response .= "Error: $error\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub GET_OK_200 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub GET_OK_200_favicon {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: image/x-icon\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub GET_OK_200_with_cache_control {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "Cache-Control: max-age=31536000\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}



sub GET_OK_200_with_cookie{
    my ($data, $cookie) = @_;
    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "Set-Cookie: $cookie; Path=/; HttpOnly\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub POST_OK_200 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}


sub POST_SENDFILE_200 {
    my ($data, $filename, $path) = @_;

    my $response;
    $response .= "HTTP/1.1 200 OK\r\n";
    $response .= "Location: $path\n";
    $response .= "Content-Type: application/octet-stream\r\n";
    $response .= "Content-Disposition: attachment; filename=\"$filename\"\r\n";
    $response .= "Content-Length: " . length($data) . "\r\n";
    $response .= "Connection: close\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub NOT_FOUND_404 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 404 Not Found\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data;

    return $response;
}

sub INTERNAL_SERVER_ERROR_500 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 500 Internal Server Error\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data || "Internal Server Error";

    return $response;
}

# New responses

sub BAD_REQUEST_400 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 400 Bad Request\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data || "Bad Request";

    return $response;
}

sub UNAUTHORIZED_401 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 401 Unauthorized\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data || "Unauthorized";

    return $response;
}

sub FORBIDDEN_403 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 403 Forbidden\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data || "Forbidden";

    return $response;
}

sub REDIRECT_302 {
    my ($path) = @_;

    my $response;
    $response .= "HTTP/1.1 302 Found\r\n";
    $response .= "Location: $path\r\n";
    $response .= "\r\n";

    return $response;
}

sub CREATED_201 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 201 Created\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= $data || "Resource Created";

    return $response;
}

sub NO_CONTENT_204 {
    my $response;
    $response .= "HTTP/1.1 204 No Content\r\n";
    $response .= "\r\n";

    return $response;
}

sub METHOD_NOT_ALLOWED_405 {
    my ($allowed_methods) = @_;

    my $response;
    $response .= "HTTP/1.1 405 Method Not Allowed\r\n";
    $response .= "Allow: $allowed_methods\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "\r\n";
    $response .= "Method Not Allowed";

    return $response;
}

sub SERVICE_UNAVAILABLE_503 {
    my ($data) = @_;

    my $response;
    $response .= "HTTP/1.1 503 Service Unavailable\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "Retry-After: 3600\r\n";  # Retry after 1 hour
    $response .= "\r\n";
    $response .= $data || "Service Unavailable";

    return $response;
}


1;
