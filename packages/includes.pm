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

# Add library path
use lib '.';

# Custom modules
use HTTP_Request;
use html_pages;
use HTTP_RESPONSE;
use webSocket_utils;
use menu_utils;
use smtp_server;
use user_control;
use database_utils;

1;  # Return true to indicate successful loading
