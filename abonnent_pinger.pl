#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Socket;

use DBI;
use EV;
use AnyEvent::Socket;
use AnyEvent::FastPing;

my @hosts; # pishutsa v binarnom vide ip adresa uzlov
my %hosts_rtt;
my %school_id_and_ip = (); # pustoy hash s 

#parametri skorosti oprosa(Dvijka AnyEvent)
my $max_rtt = 2;
my $interval= 100;

my $db="127.0.0.1";
my $dbsid="ironleg";
my $schema="ironleg";
 $ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";


my $dbuser= 'ping_checker';
my $dbpass= 'your_ping_pass';


$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass,{ora_ncharset => 'AL32UTF8'});

$db->{AutoCommit}=0;

my $sql_for_schools_ip = $db->prepare(qq {select * from ironleg.ats_eq_ports_v});
$sql_for_schools_ip->execute();

#chitaem bazu
my $current_line;
while($current_line = $sql_for_schools_ip->fetchrow_hashref)
{
    #zapixivaem v massiv hosts ip adress v BINARNOM vide
    push(@hosts, parse_address ($current_line->{IP}));
    #dobavlaem v hesh %school_id_and_ip klyuchi(eto ip addres) i znacheniya(eto school_id), nujen dlya vstavki v opredelennuyu zapis v tabliche[A  
    $school_id_and_ip{$current_line->{IP}} = $current_line->{SCHOOL_ID};
}
undef $current_line;


my $done_ping = AnyEvent->condvar;
my $pinger = new AnyEvent::FastPing;

$pinger->interval (1/$interval);
$pinger->max_rtt ($max_rtt);



$pinger->add_hosts ([@hosts]); #dobavlaem uzli kak massiv 

=main_block
 Zdes proisxodit NEBlokiruyushiy ping
=cut

$pinger->on_recv (sub {
    for (@{ $_[0] }) {
	printf "%s %g\n", (AnyEvent::Socket::format_address $_->[0]), $_->[1];
	my $rtt_reduced=substr($_->[1],0,8);
	my $ips = AnyEvent::Socket::format_address  $_->[0];
    	

	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon +=1;

	my $sql_for_insert_to_schools = $db->prepare("update ironleg.schools 
						      set ping_rtt=:rtt_reduced, 
						      ping_last=TO_DATE(:to_date,'dd/mm/yyyy HH24:MI:SS ')
						      where ironleg.schools.id=:school_id");
	$sql_for_insert_to_schools->bind_param(":rtt_reduced",$rtt_reduced);
	$sql_for_insert_to_schools->bind_param(":to_date",$mday."/".$mon."/".$year." ".$hour.":".$min.":".$sec);
	$sql_for_insert_to_schools->bind_param(":school_id",$school_id_and_ip{$ips});
	$sql_for_insert_to_schools->execute;

	#bez kommita nesmotya na warninga baza blochit tranzakchii 
	#$db->commit;

    }
  });

#kogda zakonchim(sostoyanie idle) to spokoyno umirat
$pinger->on_idle (sub {
    $db->commit;
    print "done\n";
    undef $pinger;
    exit;
		  });


#zapuskaem Dvijok
$pinger->start;
$done_ping->wait;
1;
