#!/usr/bin/perl
use warnings;
#use strict;
use utf8;
use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use GD::Graph::lines;
use Data::Dumper;

my $action=param('action');


$ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
($REMOTE_USER,$REMOTE_PASSWD) = split(/:/,decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));
if (!UserAccess($REMOTE_USER,$REMOTE_PASSWD)) { 
  print "WWW-Authenticate: Basic realm=\"test\"\n";
  print "Status: 401 Unauthorized\n\n";
  print "Error\n";
  exit; 
}

print "Content-type: text/html\n\n"; 

&shab ("/var/www/html/ironleg/shab_top");

print "Hello $REMOTE_USER!";
       
$db="127.0.0.1";
$dbsid="IRONLEG";
$schema="ironleg";
$table="city_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";

$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass);

$sql0=$db->prepare(qq{SELECT Privilege 
		      FROM user_tab_privs
		      WHERE owner = upper('$schema')
		      AND Grantee = upper('$dbuser')
		      AND Table_Name = upper('$table')});
 $sql0->execute();
$privs_list="";
  while ($privs = $sql0->fetchrow_array)
  {
    $privs_list = $privs_list."_".$privs;
  }
    

print "<br><a href='/cgi-bin/reports.pl?action=schools_traf'>Schools Traf</a>
           <a href='/cgi-bin/reports.pl?action=ats_eq_logs'>Equipment Logs</a>
           <a href='/cgi-bin/reports.pl?action=delta_con'>Delta Connections</a>
           <a href='/cgi-bin/reports.pl?action=active_clients'>Active Schools</a>
           <a href='/cgi-bin/monitoring.pl'>Monitoring</a>
           <a href='/cgi-bin/reports.pl?action=dhcp_requests'>DHCP Requests</a>";



my $now_date=`date +"%D %R"`;
my $start_time_of_count;
if ($action ne 'month')
{
	my $day_of_week=`date +"%u"`;

  $start_time_of_count = `date --date="3 days ago" +"%D"`;


	if ($day_of_week == 6) { $start_time_of_count = `date --date="4 days ago" +"%D"` };
	if ($day_of_week == 7) { $start_time_of_count = `date --date="5 days ago" +"%D"` };
	if ($day_of_week == 1) { $start_time_of_count = `date --date="5 days ago" +"%D"` };
	if ($day_of_week == 2) { $start_time_of_count = `date --date="4 days ago" +"%D"` };

}
else
{ $start_time_of_count = `date --date="1 month ago" +"%D"` };

print "<br>Start date is $start_time_of_count End date is $now_date  <br><br>";

print "<br><a href=/cgi-bin/monitoring.pl?action=month>month</a>  <a href=/cgi-bin/monitoring.pl>last 3 work day</a>";

my $sql1=$db->prepare("SELECT  school_id, city_name, school_name ,sum(download)  from  ironleg.school_traf_v  WHERE 
traf_date between   to_date('$start_time_of_count','mm/dd/yy') and to_date('$now_date','mm/dd/yy HH24:MI')
 group by school_id, city_name , school_name  HAVING SUM(download)=0 order by city_name,school_name");
$sql1->execute();

print "<table  width='100%' border='1' cellspacing='1' cellpadding='1'> <td>
<tr>
  <td> N </td>
   <td>
     City
   </td>
   <td> 
 School 
   </td>
   <td> 
 Contacs
   </td>
<td>
Ping time (second)
</td>
<td>
Time of last ping response
</td>
   <td> 
     Cause
   </td>
</td>
";

my ($city_name,$school_name);
my $i;
while( ($school_id,$city_name,$school_name)= $sql1->fetchrow_array)
{
    $i++;
    
 
   # my $sql_for_last_seen =$db->prepare("SELECT max(traf_date) from ironleg.schools_traf_p where school_id=$school_id and download > 0  and traf_date  between   to_date('$start_time_of_count','mm/dd/yy') and to_date('$now_date','mm/dd/yy HH24:MI') ");
    #$sql_for_last_seen->execute;
   #my ($last_seen_date,$last_seen_time) = $sql_for_last_seen->fetchrow_array;

#   SELECT max(traf_date) from ironleg.schools_traf_p
# where school_id='284' and download > 0  and schools_traf_p.traf_date  between   to_date('06/01/12','mm/dd/yy') and to_date('#07/20/12 17:04  ','mm/dd/yy HH24:MI') 
 #
#
    my $sql_for_contacts= $db->prepare("select name,phone,type_name from ironleg.school_contacts_v where school_id=$school_id");

    $sql_for_contacts->execute;

    

    my $contacts_output;
    while( my ($name, $phone , $type_name) =  $sql_for_contacts->fetchrow_array)
    {
	$contacts_output=  $contacts_output . $name ." " . $phone . " ". $type_name . "<br>";
    }
 	

     my $sql_for_rtt_time = $db->prepare("select to_char(ping_rtt,'0.0000'),to_char(ping_last,'dd/mm/yy HH24:MI:SS') from ironleg.schools_v where id=$school_id");
     $sql_for_rtt_time->execute;
 
    my ($ping_rtt, $ping_last) =  $sql_for_rtt_time->fetchrow_array;

  
=for_client_type
    my $sql_for_clients_types = $db->prepare("select ");
    $sql_for_clients_types->execute;

    my $type_name = $sql_for_clients_types->fetchrow_array;
=cut


    print "<tr>
            <td> $i</td>
            <td>$city_name </td>
            <td> <a href=/cgi-bin/schools_info.pl?school_id=$school_id>$school_name</a> </td>
            <td>  $contacts_output <br> </td>
            <td> $ping_rtt </td>
            <td> $ping_last</td>
            <td> undefined </td>
          </tr>";


}
print "<br>Всего : $i";
undef $i;

print "<table>";

sub UserAccess { 
  $db="127.0.0.1";
  $dbsid="IRONLEG";
  $dbuser=$_[0];
  $dbpass=$_[1];
  $ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";
  $ENV{ORACLE_HOME}="/opt/oracle/product/11.2.0/db";

    if ($db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass))
	{$res=1}
    else
	{$res=0}

  return $res; 
}

sub shab 
{
my ($file) = @_;
open (SHAB, "$file") or die "can't open file";
my @shablon=<SHAB>;
close (SHAB);
  foreach (@shablon) 
  {
  print "$_";
  }
}
