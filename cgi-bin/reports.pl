#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use GD::Graph::lines;
use LWP::Simple;
use Data::Dumper;
use File::ReadBackwards;

require 'abills_fetcher.pl';
require 'configurations.pl';

my $ip_not_in_base_text = 'MAC address qeydiatda deyil. MAC адрес не зарегистрирован в базе';
my $mismatch_ports_label='Mismatch ports';
my $priv_users_label='Private users stats';

my $action=param('action');
my $action2=param('action2');
my $school_id=param('school_id');
my $ats_eq_id=param('ats_eq_id');
my $date_from=param('date_from');
my $date_to=param('date_to');
my $order=param('order');
my $desc=param('desc');
my $traf=param('traf');
my $limit=param('limit');
my $city_id=param('city_id');
my $priority=param('priority');
my $rows=param('rows');

my $s_city_ats=param('s_city_ats');
my $s_eq=param('s_eq');
my $s_host=param('s_host');
my $s_msg=param('s_msg');

my $s_city_name=param('s_city_name');
my $s_school_name=param('s_school_name');

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
		      WHERE owner = upper(:schema)
		      AND Grantee = upper(:dbuser)
		      AND Table_Name = upper(:table1)});
$sql0->bind_param(":schema",$schema);
$sql0->bind_param(":dbuser",$dbuser);
$sql0->bind_param(":table1",$table);
$sql0->execute();
$privs_list="";
  while ($privs = $sql0->fetchrow_array)
  {
    $privs_list = $privs_list."_".$privs;
  }
    
#print "$privs_list";

print "<br><a href='?action=schools_traf'>Schools Traf</a>
	   <a href='?action=ats_eq_logs'>Equipment Logs</a>
	   <a href='?action=delta_con'>Delta Connections</a>
	   <a href='?action=active_clients'>Active Schools</a>
	   <a href='http://nagios.azedunet.az/'>Monitoring</a>
	   <a href='?action=dhcp_requests_registered'>DHCP Requests</a>
	   <a href='?action=dhcp_requests_unregistered'>Unknown MAC addresses</a>
           <a href='?action=port_log'>$port_activity_label</a>
           <a href='?action=mismatch_ports'>$mismatch_ports_label</a>
           <a href='?action=private_users_stats'>$priv_users_label</a>
	   ";
	   
  if ($action eq "schools_traf")
  {
    print "<form name='select' action='reports.pl' method='get'>";
    print "<table border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><td valign='top'>";
    print "<table border='1' cellspacing='1' cellpadding='1' align='left'>";
      if ($date_from eq '')
      {
        $date_from = `/bin/date +\"%Y-%m-%d\"`;
        chomp($date_from);
        $date_to = `/bin/date -d "next day" +"%Y-%m-%d"`;
        chomp($date_to);
        $order = 'port';
      }
    print "<tr><td width=40%>From: <td><input type='text' size='8' name='date_from' value='$date_from'>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date_from);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
    print "<tr><td>To: <td><input type='text' size='8' name='date_to' value='$date_to'>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date_to);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";

    print "<tr><td>Trafic: <td><select name='traf'>";
    print "<option value='KByte'"; if ($traf eq 'KByte'){print "selected"}print ">KByte</option>";
    print "<option value='MByte'"; if ($traf eq 'MByte'){print "selected"}print ">MByte</option>";
    print "<option value='GByte'"; if ($traf eq 'GByte'){print "selected"}print ">Gbyte</option>";
    print "</select>";
    
    print "<tr><td valign=top>Order: <td><select name='order'>";
    print "<option value='school_name'"; if ($order eq 'school_name'){print "selected"}print ">School Name</option>";
    print "<option value='city_name'"; if ($order eq 'city_name'){print "selected"}print ">City Name</option>";
    print "<option value='download'"; if ($order eq 'download'){print "selected"}print ">Download</option>";
    print "<option value='upload'"; if ($order eq 'upload'){print "selected"}print ">Upload</option>";
    print "<option value='total'"; if ($order eq 'total'){print "selected"}print ">Total</option>";
    print "</select>";
    print "<br>Desc <input type='checkbox' name='desc' value='desc'"; if ($desc ne ''){print 'checked'}print">";
    print "<tr><td>Rows: <td><select name='rows'>";
    print "<option value='20'>20</option>";
    print "<option value='50'";if($rows eq '50'){print "selected"}print">50</option>";
    print "<option value='100'";if($rows eq '100'){print "selected"}print">100</option>";
    print "<option value='100000'";if($rows eq '100000'){print "selected"}print">All</option>";
    print "</select>";
    print "<input type='hidden' name='action' value='schools_traf'>";
    print "<input type='hidden' name='action2' value='report'>";
    print "<tr><td>&nbsp;<td><input type=submit>";
    print "</table>";
    $date_from =~ /(\d{2})-(\d+)-(\d+)/;
    $unix_date_from = "$1$2$3"."0000";
    $date_to =~ /(\d{2})-(\d+)-(\d+)/;
    $unix_date_to = "$1$2$3"."0000";
    $seconds_from = `/bin/date -j $unix_date_from +%s`;
    chomp($seconds_from);
    $seconds_to = `/bin/date -j $unix_date_to +%s`;
    chomp($seconds_to);
    $seconds = $seconds_to-$seconds_from;
        if ($action2 eq "report")
        {
            if ($traf eq "KByte"){$divider = 1024}
            if ($traf eq "MByte"){$divider = 1048576}
            if ($traf eq "GByte"){$divider = 1073741824}
	    $select1 = "SELECT school_id, city_name, school_name, round(sum(download)/$divider,2) as download, round(sum(upload)/$divider,2) as upload, round(sum(total)/$divider,2) as total
			FROM $schema.school_traf_v
			WHERE traf_date between to_date(:date_from,'YYYY-MM-DD') and to_date(:date_to,'YYYY-MM-DD')";
	    $select1 .= " AND upper(city_name) like upper(:s_city_name)";
	    $select1 .= " AND upper(school_name) like upper(:s_school_name)";
 	    $select1 .=	" GROUP by school_id, city_name, school_name
			  ORDER by :order1 :desc1";
            $select = "SELECT rownum, c.*
		       FROM ($select1) c
		       WHERE rownum <= $rows";
            print "<td width='80%' valign='top'>";
            my $sql0 = $db->prepare("$select");
	    $sql0->bind_param(":date_from",$date_from);
	    $sql0->bind_param(":date_to",$date_to);
	    $sql0->bind_param(":s_city_name","%".$s_city_name."%");
	    $sql0->bind_param(":s_school_name","%".$s_school_name."%");
	    $sql0->bind_param(":order1",$order);
	    $sql0->bind_param(":desc1",$desc);
            $sql0->execute;
            print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
            print "<tr><th width=10>&nbsp;
                       <th width=8%>City
                       <th width=50%>School
                       <th>Graph
                       <th>Download Traffic ($traf)
                       <th>Upload Traffic ($traf)
                       <th>Total Traffic ($traf)
                       ";
	    print "<tr><td>&nbsp;
		       <td><input size=8 type=text name='s_city_name' value='$s_city_name'>
		       <td><input type=text name='s_school_name' value='$s_school_name'>
		       <td colspan=4 align=right><input type=submit>";
            $i=1;
	    $sql1 = $db->prepare("select to_date('$date_to','YYYY-MM-DD') - to_date('$date_from','YYYY-MM-DD') from dual");
            $sql1->execute;
	    $interval = $sql1->fetchrow_array;
	    if ($interval == 1){$label_skip = 20;$label="HH24"}
	    elsif ($interval == 2 || $interval == 3){$label_skip = 40;$label="HH24"}
	    elsif ($interval == 4 || $interval == 5){$label_skip = 60;$label="HH24"}
	    elsif ($interval == 6 || $interval == 7){$label_skip = 160;$label="DD"}
	    else{$label_skip = 400;$label="DD"}
                while (my($rownum, $school_id, $city_name, $school_name, $in_bytes, $out_bytes, $total_bytes) = $sql0->fetchrow_array)
                {
                    print "<tr valign=top>
                            <td>$rownum
                            <td>$city_name
                            <td><a href='schools_info.pl?school_id=$school_id'>$school_name";
			    
		$sql1=$db->prepare(qq{SELECT *
				      FROM (SELECT  to_char(traf_date,'$label'), 
						    round(sum(nvl(download,0))*8/1024/1024/300/4,2) as download, 
						    round(sum(nvl(upload,0))*8/1024/1024/300/4,2) as upload, 
						    round(sum(nvl(total,0))*8/1024/1024/300/4,2) as total 
					    FROM ironleg.school_traf_v st
					    WHERE traf_date between to_date(:date_from,'YYYY-MM-DD')
					    AND to_date(:date_to,'YYYY-MM-DD')
					    AND school_id = :school_id
					    GROUP BY traf_date
					    ORDER BY traf_date)});
		$sql1->bind_param(":date_from",$date_from);
		$sql1->bind_param(":date_to",$date_to);
		$sql1->bind_param(":school_id",$school_id);
		$sql1->execute();

		$j=0;
		@td="";
		@d="";
		@u="";
		    while (($t_date,$download,$upload,$total) = $sql1->fetchrow_array)
		    {
		    $td[$j] = $t_date;
		      if ($download>10){$download=10}
		      if ($upload>2){$upload=2}
		    $d[$j]= $download;
		    $u[$j]= $upload;
		    $j++;
		    }
		@data = (
		 [@td],
		  [@d],
		  [@u]
		);	      
		$graph = GD::Graph::lines->new(350, 150);
    
		$graph->set(
		    y_label           => 'MBits per second',
		    x_label_skip      => $label_skip,
		    y_label_skip      => 1
		) or die $graph->error;
		my $gd = $graph->plot(\@data) or die $graph->error;
	      
		open(IMG, ">/srv/www/htdocs/img/$school_id.gif") or die $!;
		binmode IMG;
		print IMG $gd->gif;
		close IMG;
		print "<td width=300><img src='../img/$school_id.gif'>";
		
		$traf =~ s/(\w{2}).+/$1/;
		print "                   <td align=right>$in_bytes$traf
					  <td align=right>$out_bytes$traf
					  <td align=right>$total_bytes$traf
					  ";
				  $i++;
		}
            print "<tr align=right><td>&nbsp<td>&nbsp<td>&nbsp<td>Total: <td>$sum_in<td>$sum_out<td>$sum_total";
            print "</table>";
        }
    print "</table>";
  }  
  elsif ($action eq "ats_eq_logs")
  {
    print "<form name='select' action='reports.pl' method='get'>";
    print "<table border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><td valign='top'>";
    print "<table border='1' cellspacing='1' cellpadding='1' align='left' width=100%>";
      if ($date_from eq '')
      {
        $date_from = `/bin/date +\"%Y-%m-%d\"`;
        chomp($date_from);
        $date_to = `/bin/date -d "next day" +"%Y-%m-%d"`;
        chomp($date_to);
        $order = 'port';
      }
    print "<tr><td width=40%>From: <td><input type='text' size='8' name='date_from' value='$date_from'>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date_from);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
    print "<tr><td>To: <td><input type='text' size='8' name='date_to' value='$date_to'>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date_to);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
    print "<tr><td>Priority<td><select name='priority'>";
    print "<option value='all'>All</option>";
    print "<option value='info'";if($priority eq 'info'){print "selected"}print">Info</option>";
    print "<option value='notice'";if($priority eq 'notice'){print "selected"}print">Notice</option>";
    print "<option value='alert'";if($priority eq 'alert'){print "selected"}print">Alert</option>";
    print "<option value='warning'";if($priority eq 'warning'){print "selected"}print">Warning</option>";
    print "<option value='err'";if($priority eq 'err'){print "selected"}print">Error</option>";
    print "</select>";
    print "<tr><td>Rows: <td><select name='rows'>";
    print "<option value='20'>20</option>";
    print "<option value='50'";if($rows eq '50'){print "selected"}print">50</option>";
    print "<option value='100'";if($rows eq '100'){print "selected"}print">100</option>";
    print "<option value='100000'";if($rows eq '100000'){print "selected"}print">All</option>";
    print "</select>";
    print "<input type=hidden name='action' value='ats_eq_logs'>";
    print "<input type=hidden name='ats_eq_id' value='$ats_eq_id'>";
    print "<input type=hidden name='action2' value='report'>";
    print "<tr><td>&nbsp;<td><input type=submit>";
    print "</table>";
        if ($action2 eq "report")
        {
            $select = "SELECT rownum, a.*
		       FROM (SELECT city_name,
				    ats_name,
				    type_name,
				    eq_name,
				    man_name,
				    host,
				    to_char(log_date,'DD/MM/YYYY HH24:MI:SS'),
				    priority,
				    msg
  			     FROM $schema.ats_eq_logs_v
		   WHERE log_date between to_date(:date_from,'YYYY-MM-DD') and to_date(:date_to,'YYYY-MM-DD')";
	      if ($ats_eq_id){$select.= " AND id = :ats_eq_id"}
	      if ($priority && $priority ne 'all'){$select .= " AND priority = '$priority'"}
	      if ($s_city_ats){$select .= " AND (upper(city_name) like upper('%$s_city_ats%') OR upper(ats_name) like upper('%$s_city_ats%'))"}
	      if ($s_eq){$select .= " AND (upper(type_name) like upper($s_eq) OR upper(eq_name) like upper($s_eq))"}
	      if ($s_host){$select .= " AND upper(host) = upper('$s_host')"}
	      if ($s_msg){$select .= " AND upper(msg) like upper(\%$s_msg\%)"}
	    $select .=" ORDER by log_date desc ) a
		       WHERE rownum <=$rows ";
            print "<td width='80%' valign='top'>";
            my $sql0 = $db->prepare($select);


	    $sql0->bind_param(":date_from",$date_from);
	    $sql0->bind_param(":date_to",$date_to);
	    $sql0->bind_param(":ats_eq_id",$ats_eq_id);
	    #$sql0->bind_param(":priority",$priority);
	    #$sql0->bind_param(":s_city_ats","%".$s_city_ats."%");
	    #$sql0->bind_param(":s_eq","%".$s_eq."%");
	    #$sql0->bind_param(":s_host","%".$s_host."%");
	    #$sql0->bind_param(":s_msg","%".$s_msg."%");

            $sql0->execute();
            print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
            print "<tr><th width=1>&nbsp;
                       <th width=11% >Date
		       <th>ATS
		       <th>Equipment
                       <th width=10%>Host
                       <th>Message
                       <th width=8%>Priority";
	    print "<tr><td>&nbsp;
		       <td>&nbsp;
		       <td><input size=24 type=text name='s_city_ats' value='$s_city_ats'>
		       <td><input type=text name='s_eq' value='$s_eq'>
		       <td><input size=10 type=text name='s_host' value='$s_host'>
		       <td><input size=27 type=text name='s_msg' value='$s_msg'>
		       <td><input type=submit>";
	      while (($rownum, $city_name, $ats_name, $type_name, $eq_name, $man_name, $host, $log_date, $priority, $msg)  = $sql0->fetchrow_array)
	      {
		print "<tr><td>$rownum&nbsp;
			   <td align=center>$log_date
			   <td>$city_name $ats_name
			   <td>$man_name $eq_name
			   <td>$host
			   <td>$msg
			   <td>$priority";
	      }
	}
  }
  elsif ($action eq "delta_con")
  {
    $select = "SELECT rownum, a.*
	       FROM (SELECT city_name,ats_name,man_name,name,ip
		     FROM $schema.ats_eq_v
		     WHERE (upper(type_name) like upper('%switch%') OR upper(type_name) like upper('%router%'))
		     AND ip is not null) a";
    my $sql0 = $db->prepare("$select");
    $sql0->execute;
    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><th width=1>&nbsp;
	       <th>City
	       <th>ATS
	       <th>Equipment
	       <th>IP
	       <th>Port
               <th>Graph";
      while (($rownum, $city_name, $ats_name, $man_name, $eq_name, $ip)  = $sql0->fetchrow_array)
      {
	print "<tr><td valign=top>$rownum&nbsp;
		   <td valign=top>$city_name
		   <td valign=top>$ats_name
		   <td valign=top>$man_name $eq_name
		   <td valign=top>$ip &nbsp;
                   <td valign=top>1 ";
	print "<td><iframe height=300 width=700 src='http://$path_for_images_of_mrtg/mrtg/$ip/00-01.html'></iframe> ";
      }

  }
  elsif ($action eq "active_clients")
  {
    $url = "http://$path_for_images_of_mrtg/mrtg/uniq_ips.html";
    open (GRAPH, "/usr/local/www/apache22/data/$graph_dir/$graph_file");	    
    my $content = get $url;
    $content =~ s/<p> Click to Back to <a href="index.html"> Index Page <a>//;
    $content =~ s/"(.*?\.png)/"http:\/\/$path_for_images_of_mrtg\/mrtg\/$1/g;
    $content =~ s/graph_dir/$graph_dir/eg;
    $content =~ s/<!-- Begin MRTG Block -->.*?<!-- End MRTG Block -->//s;
    print "<br><br>$content";
#    $graphs="";
#	while ($f = <GRAPH>)
#	{
#	    $f =~ s/<p> Click to Back to <a href="index.html"> Index Page <a>//;
#	    $f =~ s/"(.*?\.png)/"..\/graph_dir\/$1/;
#	    $f =~ s/graph_dir/$graph_dir/e;
#	    $graphs = $graphs.$f
#	}
 #   $graphs =~ s/<!-- Begin MRTG Block -->.*?<!-- End MRTG Block -->//s;
#    print "$graphs";	    
#    close(GRAPH);
  }
  elsif ($action eq "dhcp_requests_registered")
  {
  my $city_name_s=param('city_name_s');
  my $school_name_s=param('school_name_s');
  my $mac_s=param('mac_s');
  my $ip_s=param('ip_s');
    $select = "SELECT rownum, a.*
	       FROM (SELECT to_char(req_date,'dd/mm/yyyy hh24:mi'),
			    slot,
			    port,
			    mac,
			    gw_ip,
			    ip,
			    remote_ip,
			    city_name,
			    school_name,
			    ats_city,
			    ats_name,
			    ats_eq_name
		     FROM $schema.dhcp_requests_v
		     WHERE 1=1";
	if ($city_name_s ne ''){$select = $select . " AND upper(city_name) like upper(:city_name_s)"}
	if ($school_name_s ne ''){$select = $select . " AND upper(school_name) like upper(:school_name_s)"}
	if ($mac_s ne ''){$select = $select . " AND upper(mac) like upper(:mac_s)"}
	if ($ip_s ne ''){$select = $select . " AND ip = :ip_s"}
      $select = $select . " ORDER BY  req_date DESC , city_name, school_name) a";
    my $sql0 = $db->prepare("$select");
    if ($city_name_s ne ''){$sql0->bind_param(":city_name_s","%". $city_name_s ."%")};
    if ($school_name_s ne ''){$sql0->bind_param(":school_name_s","%". $school_name_s ."%")};
    if ($mac_s ne ''){$sql0->bind_param(":mac_s","%". $mac_s ."%")};
    if ($ip_s ne ''){$sql0->bind_param(":ip_s",$ip_s)};
    $sql0->execute;
    print "<form action='reports.pl' method='get'>";
    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><th width=1>&nbsp;
	       <th>City</th>
	       <th>School</th>
	       <th>Date</th>
	       <th>MAC</th>
	       <th>IP</th>
	       <th>Slot</th>
	       <th>Port</th>
	       <th>GW</th>
	       <th>ATS City</th>
	       <th>ATS</th>
	       <th>Equipment</th>";
    print "<tr><td>&nbsp</td>
		<td><input type=text name='city_name_s' value='$city_name_s'></td>
		<td><input type=text name='school_name_s' value='$school_name_s'></td>
		<td>&nbsp</td>
		<td><input type=text name='mac_s' value='$mac_s'></td>
		<td><input type=text name='ip_s' value='$ip_s'></td>
		<input type=hidden name=action value='dhcp_requests_registered'>
		<td colspan=6 align=right><input type=submit></td>
	   </tr>";
      while (($rownum, $req_date, $slot, $port, $mac, $gw_ip, $ip, $remote_ip, $school_city, $school_name, $ats_city, $ats_name, $ats_eq_name)  = $sql0->fetchrow_array)
      {
	print "<tr><td>$rownum &nbsp;
		   <td valign=top>$school_city &nbsp;
		   <td valign=top>$school_name &nbsp;
		   <td valign=top>$req_date &nbsp;
		   <td valign=top>$mac &nbsp;
		   <td valign=top>$ip &nbsp;
		   <td valign=top>$slot &nbsp;
		   <td valign=top>$port &nbsp;
		   <td valign=top>$gw_ip &nbsp;
		   <td valign=top>$ats_city &nbsp;
		   <td valign=top>$ats_name &nbsp;
		   <td valign=top>$ats_eq_name &nbsp;
		</tr>";
      }
    print "</tr></table>";
    print "</form>";
  }
  elsif ($action eq 'dhcp_requests_unregistered')
  {
        my $city_name_s=param('city_name_s');
  my $school_name_s=param('school_name_s');
  my $mac_s=param('mac_s');
  my $ip_s=param('ip_s');
    $select = "select to_char(req_date,'dd/mm/yy HH24:MI:SS') as req_date,slot,port,mac,gw_ip,remote_ip 
               from  RADIUS_IRONLEG.ats_eq_info 
               where to_char(req_date,'dd-mm-yyyy') = to_char(sysdate,'dd-mm-yyyy')
                and ip = '0' ";
	if ($city_name_s ne ''){$select = $select . " AND upper(city_name) like upper(:city_name_s)"}
	if ($mac_s ne ''){$select = $select . " AND upper(mac) like upper(:mac_s)"}
      $select = $select . " ORDER BY req_date desc";
    my $sql0 = $db->prepare("$select");
    if ($city_name_s ne ''){$sql0->bind_param(":city_name_s","%". $city_name_s ."%")};
    if ($school_name_s ne ''){$sql0->bind_param(":school_name_s","%". $school_name_s ."%")};
    if ($mac_s ne ''){$sql0->bind_param(":mac_s","%". $mac_s ."%")};
    if ($ip_s ne ''){$sql0->bind_param(":ip_s",$ip_s)};
    $sql0->execute;
    print "<form action='reports.pl' method='get'>";
    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><th width=1>&nbsp;
	       <th>Date</th>
	       <th>MAC</th>
	       <th>IP</th>
	       <th>Slot</th>
	       <th>Port</th>
	       <th>GW</th>
	       <th>ATS City</th>
	       <th>ATS</th>
	       <th>Equipment</th>";
    print "<tr><td>&nbsp</td>
		<td><input type=text name='city_name_s' value='$city_name_s'></td>
		<td><input type=text name='school_name_s' value='$school_name_s'></td>
		<td>&nbsp</td>
		<td><input type=text name='mac_s' value='$mac_s'></td>
		<td><input type=text name='ip_s' value='$ip_s'></td>
		<input type=hidden name=action value='dhcp_requests'>
		<td colspan=6 align=right><input type=submit></td>
	   </tr>";
      while (( $req_date, $slot, $port, $mac, $gw_ip, $ip, $remote_ip)  = $sql0->fetchrow_array)
      {
	print "<tr><td> &nbsp;
		   <td valign=top>$req_date &nbsp;
		   <td valign=top>$mac &nbsp;
		   <td valign=top>$ip &nbsp;
		   <td valign=top>$slot &nbsp;
		   <td valign=top>$port &nbsp;
		   <td valign=top>$gw_ip &nbsp;
		   <td valign=top>$ats_city &nbsp;
		   <td valign=top>$ats_name &nbsp;
		   <td valign=top>$ats_eq_name &nbsp;
		</tr>";
      }
    print "</tr></table>";
    print "</form>";
      
  }
  elsif ($action eq 'port_log')
  {
   print "
    <form action='reports.pl' method='get'>
    <table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'> 
        <tr><th width=1>&nbsp;
	       <th>Date</th>
	       <th>user</th>
	       <th>action</th>
	       <th>IP</th>
	       <th>Slot</th>
	       <th>Port</th>
	   <tr>
	</tr> ";
    
    my $fh = File::ReadBackwards->new($action_log_file) or die "can't read file: $action_log_file $! \n";
    while(defined($line = $fh->readline) )
    {
      my ($date, $user, $action,$ats_ip,$port,$slot) = split (/,/, $line);
      print "
	<tr><td>$rownum &nbsp;
		   <td valign=top>$date &nbsp;
		   <td valign=top>$user &nbsp;
		   <td valign=top>$action &nbsp;
		   <td valign=top><a href='http://$ats_ip'>$ats_ip</a> &nbsp;
		   <td valign=top>$slot &nbsp;
		   <td valign=top>$port &nbsp;
		 </tr> ";
    }

  print "      
      </tr></table>
      </form>
    ";
  }
  elsif($action eq 'mismatch_ports')
  {
       print "
    <form action='reports.pl' method='get'>
    <table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'> 
        <tr><th width=1>&nbsp;
               <th>City</th>
	       <th>Name</th>
	       <th>Slot In DB</th>
	       <th>Port in DB</th>
	       <th>DHCP Slot</th>
	       <th>DHCP Port</th>
	       <th>IP</th>
               <th>MAC</th>
	   <tr>
	</tr> ";
  
    
    my $sql_fetch = $db->prepare('SELECT se.school_id, se.city_name, se.school_name, se.mac, aep.ip, aep.slot, aep.port, dv.slot as dhcp_slot, dv.port as dhcp_port FROM  ironleg.ats_eq_ports_v aep INNER JOIN ironleg.schools_eq_v se ON (    aep.school_id = se.school_id AND se.connected = 1 AND se.mac IS NOT NULL) INNER JOIN RADIUS_IRONLEG.dhcp_requests_v dv ON ( dv.ip = aep.ip and aep.port != dv.port)  order by se.school_name ');
       $sql_fetch->execute();
    
       my $i;
    while( my ($school_id,$city_name, $name, $mac , $ip, $slot, $port, $dhcp_slot, $dhcp_port) = $sql_fetch->fetchrow_array )
    {
	$i++;
      print "
	<tr><td>$i &nbsp;
                   <td valign=top>$city_name</td>
		   <td valign=top><a href='/cgi-bin/schools_info.pl?school_id=$school_id'>$name</a> &nbsp;
		   <td valign=top>$slot &nbsp;
		   <td valign=top>$port &nbsp;
		   <td valign=top>$dhcp_slot &nbsp;
		   <td valign=top>$dhcp_port &nbsp;
		   <td valign=top>$ip &nbsp;
                   <td valign=top>$mac &nbsp;
		 </tr> ";
    }

  print "      
      </tr></table>
      </form>
    ";
  
  }
elsif($action eq 'private_users_stats')
  {
       print "
    <form action='reports.pl' method='get'>
    <table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'> 
        <tr><th width=1>&nbsp;
               <th>City</th>
	       <th>Name</th>
	       <th>Tariff Name</th>
	       <th>IP</th>
               <th>Phone</th>
               <th>Installation Date</th>
               <th>Balance</th>
               <th>Last Payments</th>
	   <tr>
	</tr> ";
  

       my $sql_for_home ="select school_id, city_name,tarif_id,tarif_name,school_name,ip,phone,inst_date from ironleg.abils_clients_v order by inst_date desc ,city_name asc ,school_name asc";
       my $sql_fetch_from_ironleg = $db->prepare( $sql_for_home );
       $sql_fetch_from_ironleg->execute();


    
       my $i;
    while(my ($school_id,$city_name,$tarif_id,$tariff_name,$name,$ip,$phone,$installation_date) = $sql_fetch_from_ironleg->fetchrow_array)
    {
	$i++;
	my $deposit = abills_user_balance($school_id,'');
        my @payments = abills_payments($school_id);
      print "
	<tr><td>$i &nbsp;
                   <td valign=top>$city_name</td>
		   <td valign=top><a href='/cgi-bin/schools_info.pl?school_id=$school_id'>$name</a> &nbsp;
		   <td valign=top>$tariff_name &nbsp;
		   <td valign=top>$ip &nbsp;
		   <td valign=top>$phone &nbsp;
		   <td valign=top>$installation_date &nbsp;
                   <td valign=top>$deposit
                   <td valign=top>";
		   foreach my $pay (@payments) 
	           {
		       print "$pay <br>";
		   }
		   print"</tr> ";
    }

  print "      
      </tr></table>
      </form>
    ";
  
  }

  elsif($action eq "another_traf_statistics")
  {
    
        $select = "SELECT city_name,eq_name,eq_ip,slot,port,school_id,school_name,ip 
	       FROM IRONLEG.ats_eq_ports_v WHERE prov_name='AzEduNet'";
    my $sql0 = $db->prepare("$select");
    $sql0->execute;
    
    while(my ($city_name, $eq_name, $eq_ip, $slot, $port, $school_id, $school_name, $ip ) = $sql0->fetchrow_array )
    {
      $slot='0'.$slot;
      
      $url = "http://$path_for_images_of_mrtg/mrtg/$eq_ip/$slot-$port.html";
   #   open (GRAPH, "/usr/local/www/apache22/data/$graph_dir/$graph_file");	    
      my $content = get $url;
      $content =~ s/<p> Click to Back to <a href="index.html"> Index Page <a>//;
      $content =~ s/"(.*?\.png)/"http:\/\/$path_for_images_of_mrtg\/mrtg\/$1/g;
      $content =~ s/graph_dir/$graph_dir/eg;
      $content =~ s/<!-- Begin MRTG Block -->.*?<!-- End MRTG Block -->//s;
      print "<br><br>$content";
      print Dumper($content, $url);	    
      print "<tr><td>";
    # close(GRAPH);
          
          last;
    }

  } # end of another_traf_statistics
   
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
