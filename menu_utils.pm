package menu_utils;

use strict;
use warnings;


open my $log, '>>', 'server.log' or die "Cannot open log file: $!";
select( ( select($log), $| = 1 )[0] );



sub get_cookie_value {
    my ($cookie, $key) = @_;
    my @pairs = split(/; /, $cookie);
    foreach my $pair (@pairs) {
        if ($pair =~ /^$key=(.*)$/) {
            return $1;
        }
    }
    return "";
}

sub write_log {
    my ($type, $from , $message ) = @_;
    $type = uc($type);
    my $time = localtime;
    print $log "$time - [$type] [$from] $message\n";
    
}

















1;
