#!/usr/bin/perl
#use strict;
use warnings;

use Data::Dumper;
use CGI::Minimal;
use Net::SNMP;
use DBI;
use MIME::Base64;

#main variables
require 'configurations.pl';
#abills
require 'abills_fetcher.pl';

my $cgi = CGI::Minimal->new;
my $ats_ip =  $cgi->param('ats_ip');
my $port = $cgi->param('port');
my $slot = int($cgi->param('slot'));
my $tariff_name = $cgi->param('tariff_name');
my $device_type = $cgi->param('device_type');
my $action = $cgi->param('action');
my $username = $cgi->param('username');
my $abonnent_id = $cgi->param('abonnent_id');
my $sk = $cgi->param('sk');
my $from_system = $cgi->param('from_system');

my $result;


$ENV{'ORACLE_HOME'}="/opt/oracle/product/11.2.0/db";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";

my $db_host='127.0.0.1';
my $dbsid="IRONLEG";

if ($sk eq 'nxmkkN0VwoZ15Z8HBbGo')
{
    UserAccess($ironleg_dbuser,$ironleg_dbpass);
}
else
{
    $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
    ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/,decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));
    if (!UserAccess($REMOTE_USER,$REMOTE_PASSWD)) { 
	print "WWW-Authenticate: Basic realm=\"test\"\n";
	print "Status: 401 Unauthorized\n\n";
	print "Error\n";
	exit; 
    }
}

print $cgi_start_message;
print "<br><a href=$ENV{'HTTP_REFERER'}>back</a><br>";


if ( defined($abonnent_id) and defined($from_system) )
{
    abonnent_port_control();
    print Dumper($action,$username);
}


my ($session, $error) = Net::SNMP->session(
   -hostname  => $ARGV[0] || $ats_ip,
   -community => $community,
   -timeout   => $snmp_timeout ,
    );


if (!defined $session) {
    printf " ne podnalas ERROR: %s.\n", $error;
}

if ($action eq 'port_change_to_disabled' or $action eq 'port_change_to_enabled')
{
    port_status_change();
    write_log();
}

if ($action eq 'change_profile')
{
    port_profile_change();
    write_log();
}

conf_save();

###############################SUBS#############################
sub write_log
{
    open (my $file,">>$action_log_file") or die "Could not open file '$filename' $!";
	my $date = localtime();
	print $file "$date,$username,$action,$ats_ip,$port,$slot \n"; 
	close($file);
}

sub port_status_change
{ 
    if ($device_type eq 'ZyXEL IES-5000M')
    {
	$snmp_port_to_change = $snmp_port_enable_disable_prefix.$slot.$port;
    }
    else
    {
	$snmp_port_to_change = $snmp_port_enable_disable_prefix.$port;
    }
   
    
    if ($action eq 'port_change_to_disabled')
    {
	#port status change
	$snmp_port_change_result = $session->set_request(-varbindlist => [ $snmp_port_to_change, INTEGER , 2 ], );
    }
    if ($action eq 'port_change_to_enabled')
    {
	$snmp_port_change_result = $session->set_request(-varbindlist => [ $snmp_port_to_change, INTEGER , 1 ], );
    }
    
    if (!defined $snmp_port_change_result) 
    {
	printf "ERROR: %s.\n", $session->error();
	$session->close();
	return 1;
	exit;
    }

}

#port profile change
sub port_profile_change()
{
    if ($device_type eq 'ZyXEL IES-5000M')
    {
	$snmp_port_to_change =  $snmp_profile_change_prefix .$slot.$port;
    }
    else
    {
	$snmp_port_to_change =  $snmp_profile_change_prefix .$port;
    }

    $adsl_profile_on_dslam = $tariff_name;
    
    if ($adsl_profile_on_dslam =~ /(\d+)\/(\d+)/)
    {
     $adsl_profile_on_dslam=$1."/4096";
    }

    print  "Setting profile(speed [download/upload] )  to port : $adsl_profile_on_dslam . \n";

    $profile_change_result = $session->set_request(-varbindlist => [ $snmp_port_to_change, OCTET_STRING , $adsl_profile_on_dslam ], );
    if (!defined $profile_change_result) 
    { 
	    #trying to set normal 1024 upload speed instead.
	    $adsl_profile_on_dslam =~ s/4096/1024/;
	    $profile_change_result = $session->set_request(-varbindlist => [ $snmp_port_to_change, OCTET_STRING , $adsl_profile_on_dslam ], );
        
    }
    
    if (!defined $profile_change_result) {
	$session->close();
	printf "ERROR: %s.\n", $session->error();
    }
    else { print "OK \n";}
}

#configuration save
sub conf_save()
{
    if ($device_type eq 'ZyXEL IES-5000M')
    {
     $save_result = $session->set_request(-varbindlist => [ $snmp_ies5000_save, INTEGER , 1 ], );

     if (!defined $save_result) 
     {
	printf "ERROR: %s.\n", $session->error();
	$session->close();
     }
    
     print Dumper($save_result);
     return ;
    } 
   
    if ($device_type eq 'ZyXEL IES-1248-51' or $device_type eq 'ZyXEL IES-1000')
    {
	$save_result = $session->set_request(-varbindlist => [ $snmp_ies1000_1248_save, INTEGER , 1 ], );

	if (!defined $save_result) 
	{
	    printf "ERROR: %s.\n", $session->error();
	    $session->close();
	}
	
	return;
    }
    else  
    {

	print "ERROR cannot find the proper device type ";
	return;
    }
}



sub UserAccess { 
  $dbuser=$_[0];
  $dbpass=$_[1];

    if ($db = DBI->connect("dbi:Oracle:host=$db_host;sid=$dbsid", $dbuser, $dbpass))
	{$res=1}
    else
	{$res=0}

  return $res; 
}

sub abonnent_port_control()
{
    my $sql_ats=$db->prepare ("select eq_ip,man_name,eq_name,slot,port from IRONLEG.ats_eq_ports_v where school_id = :school_id");
    $sql_ats->bind_param(":school_id" ,$abonnent_id);
    $sql_ats->execute();
    
    if ($action eq 'enable')
    {
	my $deposit_of_client = abills_user_balance($abonnent_id,'');
	if ( $deposit_of_client >0 )
	{
	    $action = 'port_change_to_enabled';
	    $username = $from_system;
	    ($ats_ip, $man_name, $device_type, $slot, $port) = $sql_ats->fetchrow_array;
	    $device_type=$man_name.' '.$device_type;
	}
    }
    
    if ( $action eq 'disable' )
	{
	    $action = 'port_change_to_disabled';
	    $username = $from_system;
	    ($ats_ip, $man_name, $device_type, $slot, $port) = $sql_ats->fetchrow_array;
	    $device_type=$man_name.' '.$device_type;
	}

	
    return 1;
}
1;
