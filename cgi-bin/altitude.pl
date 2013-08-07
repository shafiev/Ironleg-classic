#!/usr/bin/perl


use LWP::Simple;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $lat=param('lat');
my $lng=param('lng');

print "Content-Type: text/html\n\n";


$url = "http://ws.geonames.org/srtm3?lat=$lat&lng=$lng";
my $content = get $url;

print "$content";