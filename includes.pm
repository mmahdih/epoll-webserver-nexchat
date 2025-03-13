package includes;

use strict;
use warnings;

# Core Perl modules
use Socket;
use IO::Epoll;
use Data::Dumper;
use HTTP::Request;
use Digest::SHA qw(sha1_base64);
use JSON;
use Term::ReadKey;
use URI::Escape;
use DBI;
use Getopt::Long;
use MIME::Base64;

### Add library path
use lib 'packages/';

    # Databse modules
    use Database::DatabaseUtils;

    # Html modules
    use HtmlPages::HtmlPages;

    # Http modules
    use HttpResReq::HttpRequest;
    use HttpResReq::HttpResponse;

    # Websocket modules
    use WebSocket::WebSocketUtils;

    # Menu modules
    use Menu::MenuUtils;

    # SMTP modules
    use Smtp::SmtpServer;

    # User control modules
    use User::UserControl;

    # Request control modules
    use RequestControl::HandleGetRequests;
    use RequestControl::HandlePostRequests;

    


1;  
