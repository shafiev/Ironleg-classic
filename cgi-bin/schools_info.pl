#!/usr/bin/perl

use utf8;
use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use LWP::Simple;
use Net::SNMP;

use Data::Dumper;

require 'configurations.pl';
require 'abills_fetcher.pl';
require 'snmp.pm';

my $head_of_port_controlling_block='Port informasiya';
my $status_of_port_controlling_block='Portun statusu';
my $snr_of_port_controlling_block='SNR(Signal to Noise ratio) [ Downstream/Upstream ]';
my $quality_of_port_controlling_block='Bu sürətdə olan keyfiyyəti';
my $port_enable_of_port_controlling_block = 'Portunu aç(aktiv ələ)';
my $port_disable_of_port_controlling_block ='Portunu söndür';
my $actual_profile_of_port_controlling_block = 'Profayl portunda/Тариф выставленный на порту';
my $adsl_max_rate_download_label ='Максимальная возможная скорость( КилоБит  / сек) ';
my $adsl_max_rate_upload_label = 'Максимальная возможная исходящая скорость';
my $adsl_current_speed_label = 'Скорость соединения ( КилоБит / сек)';
my $adsl_errors_label = 'Ошибки на порту';
my $adsl_discard_label = 'Отброшенные пакеты';
my $adsl_annexm_label = 'Повышенный upload[более 1 мбит/сек](режим AnnexM)';
my $adsl_current_dowload_rate;
my $adsl_current_upload_rate;
my $user_name_to_pay_label = 'Имя в биллинге и для оплаты ';
my $day_to_end_label = 'Приблизительное количество дней до блокировки ';
my $day_to_end_port_label = 'Приблизительное количество дней до блокировки порта ';

my $snr_upstream;
my $snr_downstream;
my $download_rate;
my $upload_rate;
my $max_download_rate;
my $max_upload_rate;
my $line_quality;
my $port_status;
my $tariff_name;
my $adsl_ifInErrors;
my $adsl_ifOutErrors;
my $adsl_ifInDiscards;
my $adsl_IfOutDiscards;
my $adsl_annexm;

my $action=param('action');
my $action2=param('action2');
my $school_id=param('school_id');
my $eq_type_id=param('eq_type_id');
my $eq_id=param('eq_id');
my $se_id=param('se_id');
my $se_id_new=param('se_id_new');
my $eq_ip=param('eq_ip');
my $eq_serial=param('eq_serial');
my $eq_imei=param('eq_imei');
my $eq_mac=param('eq_mac');
my $eq_desc=param('eq_desc');
my $eq_count=param('eq_count');
my $city_id=param('city_id');
my $ats_id=param('ats_id');
my $ats_id_new=param('ats_id_new');
my $ats_eq_id=param('ats_eq_id');
my $ats_eq_ports_id=param('ats_eq_ports_id');
my $ats_eq_ports_id_new=param('ats_eq_ports_id_new');
my $date=param('date');
my $slot=param('slot');
my $port=param('port');
my $phone=param('phone');
my $ip=param('ip');
my $akt=param('akt');
my $support=param('support');
my $state=param('state');
my $connectors_list=param('connectors_list');
my $photo=param('photo');
my $desc=param('desc');
my $con_id=param('con_id');
my $file=param('file');
my $int_akt=param('int_akt');
my $moe_akt=param('moe_akt');
my $connected=param('connected');
my $prov_type=param('prov_type');
my $prov_id=param('prov_id');
my $con_type_id=param('con_type_id');
my $pilot=param('pilot');
my $tarif_id=param('tarif_id');
my $vpivci=param('vpivci');
my $pppoe=param('pppoe');
my $vpn=param('vpn');
my $vpn_user=param('vpn_user');
my $vpn_pass=param('vpn_pass');

my $ats_port;

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
$table="schools_v";
$contacts_table="school_contacts_v";
$eq_table="schools_eq_v";
$connect_table="ats_eq_ports_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";
$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass,{ora_ncharset => 'AL32UTF8'});

my $dbh2 = DBI->connect("DBI:mysql:$mysql_database:$mysql_dbserver","$mysql_username","$mysql_passworl")or print "Not conected";

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

  if ($privs_list =~ /SELECT/)
  {
    my $sql0 = $db->prepare("SELECT name,city_name,address,description,type_name,to_char(ping_rtt,'0.00000'),to_char(ping_last,'dd/mm/yy HH24:MI:SS')
                             FROM $schema.$table
                             WHERE id = :school_id");
    $sql0->bind_param(":school_id",$school_id);
    $sql0->execute;
    ($school_name,$city_name,$address,$school_desc,$type_name,$ping_rtt,$ping_last) = $sql0->fetchrow_array;
     
    my $user_name_to_pay = abills_user_info($school_id);
     
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1'>";     
    print "<tr><td width='20%' valign='top'>School Info: <br>";
    print "<table width='100%'  border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><td width=50%>City: <td>$city_name";
    print "<tr><td valign=top>Type: <td>$type_name";
    print "<tr><td valign=top>School Name: <td>$school_name";
    print "<tr><td>Address<td>$address".'&nbsp';
    print "<tr><td>Description: <td>$school_desc &nbsp;";
    print "<tr><td>Last time of ping response <td> $ping_last &nbsp; ";
    print "<tr><td>Last Round-trip delay time of ping(seconds)  <td> $ping_rtt &nbsp; ";
    print "<tr><td>$user_name_to_pay_label  <td> $user_name_to_pay ";
    print "</table>";
    print "</td>";
  }
  
  if ($action eq "")
  {
    
  $sql0=$db->prepare(qq{SELECT Privilege 
			FROM user_tab_privs
			WHERE owner = upper(:schema)
			AND Grantee = upper(:dbuser)
			AND Table_Name = upper(:contacts_table)});
  $sql0->bind_param(":schema",$schema);
  $sql0->bind_param(":dbuser",$dbuser);
  $sql0->bind_param(":contacts_table",$contacts_table);
  $sql0->execute();
  $privs_list_cont="";
    while ($privs_cont = $sql0->fetchrow_array)
    {
      $privs_list_cont .= "_".$privs_cont;
    }
    if ($privs_list_cont =~ /SELECT/)
    {
      print "<td width=30% valign='top'>Contacts: <br>";
      print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
      print "<form action='schools_contacts.pl' method='post' onsubmit='return func_check(this);'>";
      print "<th width=30%>Name<th>Contact Type<th>Phone Number<th>&nbsp";
      my $sql1 = $db->prepare("SELECT id,name,phone,type_name
			       FROM $schema.$contacts_table
			       WHERE school_id = :school_id");
      $sql1->bind_param(":school_id",$school_id);
      $sql1->execute;
	while (my($cont_id,$cont_name,$phone,$cont_type_name) = $sql1->fetchrow_array)
	{
	  print "<tr><td>$cont_name<td>$cont_type_name<td>$phone<td width='20'><input type='radio' name='cont_id' value='$cont_id'>";
	}
      if ($privs_list_cont =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=10>";
      print "<div align='right'>Choose action: <select name='action'>";
        if ($privs_list_cont =~ /INSERT/)
	{
	  print "<option value='add'>Add</option>";
	}      
        if ($privs_list_cont =~ /UPDATE/)
	{
	  print "<option value='edit'>Edit</option>";
	}      
        if ($privs_list_cont =~ /DELETE/)
	{
	  print "<option value='delete'>Delete</option>";
	}      
	print "</select>";
      print "<input type='hidden' name='school_id' value='$school_id'>";
      print "<input type='submit' value='Select'></div></td></tr>";
      }

      print "</form>";
      print "</table>";
    }
    else
    {
      print "<br>Insuficient privileges";
    }
    print "</td>";
    print "<script type='text/javascript'>
  	  function func_check(obj){
	    var cont_id_length = obj.cont_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!cont_id_length)
		  {
		    if (obj.cont_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<cont_id_length;i++)
		    {
		      if (obj.cont_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose contacts.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!cont_id_length)
		  {
		    if (obj.cont_id.checked == true)
		    {
		      if (confirm ('Are you sure?'))
		      {
			return true;
		      }
		      else
		      {
			return false;
		      }			  
		    }
		  }
		  else
		  {
		    for (var i=0; i<cont_id_length;i++)
		    {
		      if (obj.cont_id[i].checked == true)
		      {
			if (confirm ('Are you sure?'))
			{
			  return true;
			}
			else
			{
			  return false;
			}			  
		      }
		    }
		  }
		  alert('Choose contacts.')
		  return false;
		}
		}		
	    </script>";  
  
  
    print "<td width='20%' valign='top'>Upload File: <br>";
#    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
#    print "</table>";
#    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
#    print "<form action='schools_info.pl' method='post' enctype='multipart/form-data'>";
#    print "<tr><td>Select file: <td><input type='file' name='photo'>";
#    print "<tr><td>Description: <td><input type='text' name='desc'>";
#    print "<input type='hidden' name='action' value='upload_file'>";
#    print "<input type='hidden' name='school_id' value='$school_id'>";
#    print "<tr><td align='right' colspan=2><input type='submit'>";
#    print "</form>";
#    print "</table>";

#    print "<br><br><br><br><br>";
#    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
#    my $sth = $dbh->prepare("SELECT dir,file,description
#	                     FROM schools_schema
#			     WHERE file like '$school_id%'");
#    $sth->execute;
#        while (my($dir,$file,$desc) = $sth->fetchrow_array)
#        {
#	    print "<tr><td><a href='../upload/$file' target='_blank'>Show Image</a> <a href='schools_info.pl?action=del_image&school_id=$school_id&file=$file'> Delete Image</a>";
#	}    
#    print "</table>";
    print "</td>";

  $sql0=$db->prepare(qq{SELECT Privilege 
			FROM user_tab_privs
			WHERE owner = upper(:schema)
			AND Grantee = upper(:dbuser)
			AND Table_Name = upper(:eq_table)});
  $sql0->bind_param(":schema",$schema);
  $sql0->bind_param(":dbuser",$dbuser);
  $sql0->bind_param(":eq_table",$eq_table);
  $sql0->execute();
  $privs_list_eq="";
    while ($privs_eq = $sql0->fetchrow_array)
    {
      $privs_list_eq .= "_".$privs_eq;
    }
    if ($privs_list_eq =~ /SELECT/)
    {
      print "<tr><td colspan='3'>School Equipments:<br>";
      print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
      print "<th>Manufacturer
	     <th>Model
	     <th>Type
	     <th>Desc
	     <th>IP
	     <th>Mac
	     <th>Serial
             <th>IMEI
	     <th>Connector
	     <th>Date
	     <th>Connected
	     <th>Int Akt
	     <th>MoE Akt
	     <th>&nbsp";
      my $sql1 = $db->prepare("SELECT id, eq_name, type_name, eq_desc, ip, mac, serial, imei, to_char(inst_date,'YYYY-MM-DD'), man_name, con_name, int_akt, moe_akt, connected
			       FROM $schema.$eq_table
			       WHERE school_id = :school_id
                               ORDER BY man_name, eq_name");
      $sql1->bind_param(":school_id",$school_id);
      $sql1->execute;
      print "<form method='post' onsubmit='return func(this);'>";
	  while (my ($se_id, $eq_name, $eq_type, $eq_desc, $eq_ip, $eq_mac, $eq_serial, $eq_imei, $date, $man_name, $con_name, $int_akt, $moe_akt, $connected) = $sql1->fetchrow_array)
	  {
		  $mac_int = $eq_mac;
	      print "<tr valign=top><td>$man_name
				    <td>$eq_name
				    <td>$eq_type
				    <td>$eq_desc
				    <td>$eq_ip &nbsp;
				    <td>$eq_mac &nbsp
				    <td>$eq_serial &nbsp
                                    <td>$eq_imei &nbsp
				    <td>$con_name
				    <td>$date";
	      $ch="";	
		  if ($connected eq '1'){$ch="checked"}
		  else {$ch=""}
	      print "<td><input type='checkbox' disabled $ch>";
	      $ch="";	
		  if ($int_akt eq '1'){$ch="checked"}
		  else {$ch=""}
	      print "<td><input type='checkbox' disabled $ch>";
	      $ch="";	
		  if ($moe_akt eq '1'){$ch="checked"}
		  else {$ch=""}
	      print "<td><input type='checkbox' disabled $ch>";
  
	      print "<td><input type='radio' name='se_id' value='$se_id'>";
	  }
	    
    print "<input type='hidden' name='eq_type_id' value='$eq_type_id'>";
    print "<input type='hidden' name='school_id' value='$school_id'>";
      if ($privs_list_eq =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=15>";
      print "<div align='right'>Choose action: <select name='action'>";
        if ($privs_list_eq =~ /INSERT/)
	{
	  print "<option value='add'>Add</option>";
	}      
        if ($privs_list_eq =~ /UPDATE/)
	{
	  print "<option value='edit'>Edit</option>";
	}      
        if ($privs_list_eq =~ /DELETE/)
	{
	  print "<option value='delete'>Delete</option>";
	}      
	print "</select>";
      print "<input type='submit' value='Select'></div></td></tr>";
      }
    print "</form></table>";
    print "<script type='text/javascript'>
  	  function func(obj){
	    var se_id_length = obj.se_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!se_id_length)
		  {
		    if (obj.se_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<se_id_length;i++)
		    {
		      if (obj.se_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose equipment.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!se_id_length)
		  {
		    if (obj.se_id.checked == true)
		    {
		      if (confirm ('Are you sure?'))
		      {
			return true;
		      }
		      else
		      {
			return false;
		      }			  
		    }
		  }
		  else
		  {
		    for (var i=0; i<se_id_length;i++)
		    {
		      if (obj.se_id[i].checked == true)
		      {
			if (confirm ('Are you sure?'))
			{
			  return true;
			}
			else
			{
			  return false;
			}			  
		      }
		    }
		  }
		  alert('Choose equipment.')
		  return false;
		}
		}		
	    </script>";

    }
    else
    {
      print "<tr><td colspan='3'>School Equipments: Insuficient privileges<br>";
    }
    
    
  $sql0=$db->prepare(qq{SELECT Privilege 
			FROM user_tab_privs
			WHERE owner = upper(:schema)
			AND Grantee = upper(:dbuser)
			AND Table_Name = upper(:connect_table)});
  $sql0->bind_param(":schema",$schema);
  $sql0->bind_param(":dbuser",$dbuser);
  $sql0->bind_param(":connect_table",$connect_table);
  $sql0->execute();
  $privs_list_connect="";
    while ($privs_connect = $sql0->fetchrow_array)
    {
      $privs_list_connect .= "_".$privs_connect;
    }
    if ($privs_list_connect =~ /SELECT/)
    {
    print "<tr><td colspan='3'>Connecting Info:<br>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<th>City
	   <th>Provider
	   <th>Connection Type
	   <th>VPI/VCI
	   <th>Tarif
	   <th>ATS
	   <th>ATS Equipment
	   <th>Slot
	   <th>Port
	   <th>IP Address
	   <th>Phone Number
	   <th>Connector
	   <th>Date
           <th>IPoE
           <th>Pilot
	   <th>AKT
	   <th>State          
	   <th>&nbsp";
    $sql1 = $db->prepare("SELECT id, to_char(inst_date,'DD/MM/YYYY'), ip, city_name, ats_name, eq_name, man_name, eq_ip, slot, port, phone, state, akt, con_type_name, prov_name, pilot, tarif_name, vpivci, pppoe
			  FROM $schema.ats_eq_ports_v
			  WHERE school_id = :school_id");
    $sql1->bind_param(":school_id",$school_id);
    $sql1->execute;  


    print "<form name='select' action='schools_info.pl' method='post'>";
	while (($ats_eq_ports_id,$date,$ip,$city,$ats,$ats_eq_name,$man_name,$ats_eq_ip,$slot,$port,$phone,$state,$akt,$con_type_name,$prov_name,$pilot,$tarif_name,$vpivci,$pppoe) = $sql1->fetchrow_array)
	{
#	    my $sth = $dbh->prepare("SELECT ae.name, m.name, ae.ip
#	                             FROM ats_eq ae, manufacturer m
#	                             WHERE ae.id = '$ats_eq_id'
#				     AND ae.man_id = m.id");
#	    $sth->execute;
#	    ($ats_eq_name,$man_name,$ats_eq_ip) = $sth->fetchrow_array;
	    $ats_eq_name_m = $man_name." ".$ats_eq_name;
		if ($prov_name eq ""){$prov_name="AzEduNet"}

	    $tariff_name = $tarif_name;
	    $g_port = sprintf("%02d", $port);
	    $g_slot = sprintf("%02d", $slot);
	    #$ats_eq_ip =~ s/(.+?)\s/$1/;
	    print "<tr valign='top'>
		       <td>$city
		       <td>$prov_name &nbsp;
		       <td>$con_type_name
		       <td>$vpivci &nbsp;
		       <td>$tarif_name
		       <td>$ats
		       <td>$ats_eq_name_m &nbsp;
		       <td>$slot &nbsp;
		       <td>$port &nbsp;
		       <td>$ip
		       <td>$phone";
	              
	    print "<td>";
	    $p_name = $prov_name;
	    $a_ip = $ats_eq_ip;
	    $a_eq_n = $ats_eq_name_m;
	    $cl_ip = $ip;
	    $ats_city= $city;
	    my $sql2 = $db->prepare("select $schema.schools_connectors(:ats_eq_ports_id) from dual");
            $sql2->bind_param(":ats_eq_ports_id",$ats_eq_ports_id);
	    $sql2->execute;
	    $cursor = $sql2->fetchrow_array;
	      while ( $con_name = $cursor->fetchrow_array )
	      {
		print "$con_name <br>";
	      }

	    print "<td>$date";
	    $ch="";	
		if ($pppoe eq '1'){$ch="checked"}
		else {$ch=""}
	    print "<td><input type='checkbox' disabled $ch>";
	    $ch="";	
		if ($pilot eq '1'){$ch="checked"}
		else {$ch=""}
	    print "<td><input type='checkbox' disabled $ch>";
	    $ch="";	
		if ($akt eq '1'){$ch="checked"}
		else {$ch=""}
	    print "<td><input type='checkbox' disabled $ch>";
	    $ch="";	
		if ($state eq '1'){$ch="checked"}
		else {$ch=""}
	    print "<td><input type='checkbox' disabled $ch>";
	    print "<td><input type='radio' name='ats_eq_ports_id' value='$ats_eq_ports_id'>";
	}
	
	mac_from_dhcp_requests($mac_int);

	
      if ($privs_list_connect =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=20>";
      print "<div align='right'>Choose action: <select name='action'>";
        if ($privs_list_connect =~ /INSERT/)
	{
	    print "<option value='add_connect'>Add</option>";
	  print "<option value='vpn'>Show VPN</option>";
	 
	}      
        if ($privs_list_connect =~ /UPDATE/)
	{
	  print "<option value='edit_connect'>Edit</option>";
	}      
        if ($privs_list_connect =~ /DELETE/)
	{
	  print "<option value='delete_connect'>Delete</option>";
	}      
	print "</select>";
      print "<input type='submit' value='Select'></div></td></tr>";
      }
    print "<input type='hidden' name='city_id' value='$city_id'>";
    print "<input type='hidden' name='ats_id' value='$ats_id'>";
    print "<input type='hidden' name='school_id' value='$school_id'>";

    print "</form>";
    print "</table>";
    }
    else
    {
      print "<tr><td colspan='3'>School Equipments: Insuficient privileges<br>";
    }
    
   
#port status and port contoling block

  

if (snmp_fetch_data($a_ip))
{
#print "<tr><td width=100%>";
 print <<START_OF_BLOCK;
  <tr>
      <td> $head_of_port_controlling_block</td>
  </tr>
  <tr>
      <td>$status_of_port_controlling_block</td>
      <td>
	  $snr_of_port_controlling_block
      </td>
      <td>
	  $quality_of_port_controlling_block
      </td>
      <td>
	  $actual_profile_of_port_controlling_block
      </td>
    </tr>
    <tr>
      <td>$port_status</td>
      <td>$snr_downstream / $snr_upstream</td>
      <td>$line_quality</td>
      <td>$actual_profile</td>
    </tr>
    <tr>
      <td>$adsl_current_speed_label</td>
      <td>$adsl_errors_label</td>
      <td>$adsl_annexm_label</td>
      <td>$adsl_max_rate_download_label</td>
    </tr>
    <tr>
      <td> $download_rate / $upload_rate </td>
      <td> $adsl_ifInErrors /  $adsl_ifOutErrors </td>
      <td> $adsl_annexm</td>
      <td>$max_download_rate / $max_upload_rate</td>
    </tr>

START_OF_BLOCK
       
       if ( $REMOTE_USER ~~ @users_to_port_controlling )
       {
print "
       <tr> 
        <form action='port_control.pl' method='get'>
           <td><input type='hidden' name='ats_ip' value='$a_ip' /></td>
	   <td><input type='hidden' name='port' value='$g_port' /></td>
           <td><input type='hidden' name='slot' value='$g_slot' /></td>
	   <td><input type='hidden' name='device_type' value='$ats_eq_name_m'/></td>
	   <td><input type='hidden' name='username' value='$REMOTE_USER'/></td>
	   <td><input type='hidden' name='tariff_name' value='$tariff_name'/></td>
           <tr>
	       <td><input type='submit' name='action' value='port_change_to_disabled' /></td>
	       <td><input type='submit' name='action' value='port_change_to_enabled' /></td>
	       <td><input type='submit' name='action' value='change_profile' title='' /> </td>
	   </tr>
	 </form>
";
       }
print '
   </tr>
  </tr>';

#print "</td></tr>";

}


#end of |port status and port contoling block |

    $sql0=$db->prepare(qq{SELECT Privilege 
			  FROM user_tab_privs
			  WHERE owner = upper(:schema)
			  AND Grantee = upper(:dbuser)
			  AND Table_Name = upper('clients_payments_v')});
    $sql0->bind_param(":schema",$schema);
    $sql0->bind_param(":dbuser",$dbuser);
    $sql0->execute();
    $privs_list_connect="";
      while ($privs_connect = $sql0->fetchrow_array)
      {
	$privs_list_connect .= "_".$privs_connect;
      }
      if ($privs_list_connect =~ /SELECT/)
      {
=payments
	  print "<tr><td colspan='3'>Payments Info:<br>";
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
	  print "<form method=get action='clients_payments.pl'>";
	  print "<tr><th>Date<th>Amount<td width='1%'>&nbsp;";
	  $sql1 = $db->prepare("SELECT id,to_char(payment_date,'YYYY-MM-DD'), amount
				FROM $schema.clients_payments_v
				WHERE client_id = :school_id
				ORDER BY payment_date");
	  $sql1->bind_param(":school_id",$school_id);
	  $sql1->execute;
	    while (my($payment_id,$payment_date,$amount) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$payment_date
			 <td>$amount
			 <td><input type=radio name='payment_id' value='$payment_id'>";
	    }
	  $sql1 = $db->prepare("SELECT sum(amount)
				FROM $schema.clients_payments_v
				WHERE client_id = :school_id");
	  $sql1->bind_param(":school_id",$school_id);
	  $sql1->execute;
	  $sum_amount = $sql1->fetchrow_array;
	  $sql1 = $db->prepare("SELECT $schema.balance(:school_id)
				FROM dual");
	  $sql1->bind_param(":school_id",$school_id);
	  $sql1->execute;
	  $balance = $sql1->fetchrow_array;
	  print "<tr><td align=right><b>Total:
		     <td>$sum_amount
		     <td>&nbsp;";
	  print "<tr><td align=right><b>Balance:
		     <td>$balance
		     <td>&nbsp;";                 
	  print "</table>";
	  if ($privs_list_connect =~ /INSERT|UPDATE|DELETE/)
	  {
	  print "<tr><td colspan=20>";

	  print "<div align='right'>Choose action: <select name='action'>";
	    if ($privs_list_connect =~ /INSERT/)
	    {
	      print "<option value='add'>Add</option>";
	    }      
	    if ($privs_list_connect =~ /UPDATE/)
	    {
	      print "<option value='edit'>Edit</option>";
	    }      
	    if ($privs_list_connect =~ /DELETE/)
	    {
	      print "<option value='delete'>Delete</option>";
	    }      
	    print "</select>";
	  print "<input type=hidden name='school_id' value='$school_id'>";
	  print "<input type='submit' value='Select'></div></td></tr>";
=cut
	  print "</form>";
	 # }

          if ( $type_name ~~ @private_users_group )
	  {
      #Abills user info

	      abills_user_balance($school_id,'with_html');


	      my $days_to_block  = abills_deposit_time_fetcher($school_id);

	      print "<table width='100%' border='2' cellspacing='1' cellpadding='1'>";
	      print "<tr> <th> $day_to_end_label </th><th>  $days_to_block </th></tr>";
	      print "</table>";
       #End of Abills 
        } 
      }
      else
      {
	print "<tr><td colspan='3'>Insuficient privileges<br>";
      }

#mrtg block
	if ($p_name eq "AzEduNet")
	{
	    $graph_dir = "mrtg/$a_ip";
	      if ($g_slot == 0 and not ($a_eq_n =~ /Cisco/))
	      {
		$g_slot = "01"
	      }
	    $graph_file = "$g_slot-$g_port.html";
	}
	else
	{
	    $graph_dir = "mrtg/$p_name";
	    $graph_file = "$cl_ip.html";	    
	}
     
    $url = "http://$path_for_images_of_mrtg/$graph_dir/$graph_file";
    open (GRAPH, "/usr/local/www/apache22/data/$graph_dir/$graph_file");	    
    print "<tr><td colspan=10 align=center>";
    my $content = get $url;
    $content =~ s/<p> Click to Back to <a href="index.html"> Index Page <a>//;
    $content =~ s/"(.*?\.png)/"http:\/\/$path_for_images_of_mrtg\/graph_dir\/$1/g;
    $content =~ s/graph_dir/$graph_dir/eg;
    $content =~ s/<!-- Begin MRTG Block -->.*?<!-- End MRTG Block -->//s;
    print "<table width='100%' border='1' cellspacing='1' cellpadding='1'>";
    print "<tr><td width=50%>";
    print "$content";
    $graphs="";
	while ($f = <GRAPH>)
	{
	    $f =~ s/<p> Click to Back to <a href="index.html"> Index Page <a>//;
	    $f =~ s/"(.*?\.png)/"..\/graph_dir\/$1/;
	    $f =~ s/graph_dir/$graph_dir/e;
	    $graphs = $graphs.$f
	}
    $graphs =~ s/<!-- Begin MRTG Block -->.*?<!-- End MRTG Block -->//s;
    print "$graphs";	    
    close(GRAPH);
    print "<td valign=top>";

=zakomentirovaniya
    print "<H3>Netflow Traffic Analysis for $cl_ip IP Address </H3><br>";
    print "<h4>Daily Graph (5 Minute Average)</h4> ";
      $sql1=$db->prepare(qq{SELECT *
			    FROM (SELECT  to_char(traf_date,'HH24'), 
					  round(sum(nvl(download,0))*8/1024/300,2) as download, 
					  round(sum(nvl(upload,0))*8/1024/300,2) as upload, 
					  round(sum(nvl(total,0))*8/1024/300,2) as total 
				  FROM ironleg.school_traf_v st
				  WHERE school_id = :school_id
				  AND traf_date between sysdate-1.5
				  AND sysdate
				  GROUP BY traf_date
				  ORDER BY traf_date)});
      $sql1->bind_param(":school_id",$school_id);
      $sql1->execute();

      $j=0;
      @td="";
      @d="";
      @u="";
      ($max_down,$max_up,$sum_down,$sum_up)=0;
	  while (($t_date,$download,$upload,$total) = $sql1->fetchrow_array)
	  {
	  $td[$j] = $t_date;
	  $d[$j]= $download;
	    if ($download > $max_down){$max_down=$download}
	  $sum_down += $download;
	  $u[$j]= $upload;
	    if ($upload > $max_up){$max_up=$upload}
	  $sum_up += $upload;	    
	  $j++;
	  }
      $cur_down = $d[$j-1];
      $cur_up = $u[$j-1];
if ($j != 0 ) {
      $avg_down = sprintf("%.2f",$sum_down/$j);
      $avg_up = sprintf("%.2f",$sum_up/$j);
}
else { $avg_down = 0; $avg_up = 0;}      
@data = (
       [@td],
	[@d],
	[@u]
      );	      
      $graph = GD::Graph::lines->new(500, 150);
      $max_down;
      $graph->set(
	  y_label           => 'KBits per second', 
	  x_label_skip      => 20
      ) or die $graph->error;
      my $gd = $graph->plot(\@data) or die $graph->error;
    
      open(IMG, ">/var/www/html/img/d_$school_id.gif") or die $!;
      binmode IMG;
      print IMG $gd->gif;
      close IMG;
      print "<img src='../img/d_$school_id.gif'>";
      
      $traf =~ s/(\w{2}).+/$1/;
			$i++;
    print "<table width=100%> 
	<tr> 
		<th></th> 
		<th scope='col'>Max</th> 
		<th scope='col'>Average</th> 
		<th scope='col'>Current</th> 
	</tr> 
	<tr align=right> 
		<th scope='row'>In</th> 
		<td>$max_down kb/s</td> 
		<td>$avg_down kb/s</td> 
		<td>$cur_down kb/s</td> 
	</tr> 
	<tr  align=right> 
		<th scope='row'>Out</th> 
		<td>$max_up kb/s</td> 
		<td>$avg_up kb/s</td> 
		<td>$cur_up kb/s</td> 
	</tr> 
      </table>";
=cut

=nfsen
# Okno dla nfsena
 print "  <iframe src=http://82.194.0.195 height=700 width=1000></iframe>  ";
=cut
    print "</table>";
    print "</table>";

  }
  elsif ($action eq "add")
  {
    if ($school_id =~ /^\d+$/)
    {
      &add_edit_eq_form($action,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "add_db")
  {
      if ($school_id =~ /^\d+$/ && $eq_id =~ /^\d+$/ && $eq_ip =~ /^\d+\.\d+\.\d+\.\d+$|^$/ && $eq_mac =~ /\w{12}|^$/ && $eq_serial !~ /[\'\\]/i && $date =~ /\d{4}-\d{2}-\d{2}/i && $con_id =~ /^\d+$/ && $moe_akt =~ /^\d+$|^$/ && $int_akt =~ /^\d+$|^$/ && $connected =~ /^\d+$|^$/)
      {
	$query = "INSERT into $schema.$eq_table(school_id,eq_id,ip,mac,serial,imei, inst_date,con_id,int_akt,moe_akt,connected)
		  VALUES('$school_id','$eq_id','$eq_ip',upper('$eq_mac'),'$eq_serial', '$eq_imei', to_date('$date','YYYY-MM-DD'),'$con_id','$int_akt','$moe_akt','$connected')";
	$redirect = "?action=add&school_id=$school_id&eq_id=$eq_id&eq_ip=$eq_ip&eq_mac=$eq_mac&eq_serial=$eq_serial&date=$date&con_id=$con_id&int_akt=$int_akt&moe_akt=$moe_akt&connected=$connected";
	&add_edit_del_db($query,$redirect,$school_id);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($school_id =~ /^\d+$/ && $se_id =~ /^\d+$|^$/)
      {
      &add_edit_eq_form($action,$school_id,$se_id);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($se_id =~ /^\d+$/ && $school_id =~ /^\d+$/ && $eq_id =~ /^\d+$/ && $eq_ip =~ /^\d+\.\d+\.\d+\.\d+$|^$/ && $eq_mac =~ /\w{12}|^$/ && $eq_serial !~ /[\'\\]/i && $date =~ /\d{4}-\d{2}-\d{2}/i && $con_id =~ /^\d+$/ && $moe_akt =~ /^\d+$|^$/ && $int_akt =~ /^\d+$|^$/ && $connected =~ /^\d+$|^$/)
      {
	$query = "UPDATE $schema.$eq_table
		  SET school_id = $school_id,
		      eq_id = $eq_id,
		      ip = '$eq_ip',
		      mac = upper('$eq_mac'),
		      serial = '$eq_serial',
                      imei = '$eq_imei',
		      inst_date = to_date('$date','YYYY-MM-DD'),
		      con_id = $con_id,
		      int_akt = '$int_akt',
		      moe_akt = '$moe_akt',
		      connected = '$connected'
		  WHERE id='$se_id'";
	$redirect = "?action=edit&se_id=$se_id&school_id=$school_id";
	&add_edit_del_db($query,$redirect,$school_id);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($se_id =~ /^\d+$/ && $school_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$eq_table WHERE id='$se_id'";
      $redirect = "?school_id=$school_id";
      &add_edit_del_db($query,$redirect,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "add_connect")
  {
    if ($school_id =~ /^\d+$/)
    {
      &add_edit_connect_form($action,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "add_connect_db")
  {
    if ($ats_eq_id =~ /^\d+$|^$/ && $ip =~ /^\d+\.\d+\.\d+\.\d+$/ && $date =~ /^\d{4}-\d{2}-\d{2}$/i && $slot =~ /^\d+$|^$/ && $port =~ /^\d+$|^$/ && $school_id =~ /^\d+$|^$/ && $phone =~ /^\d{5,7}$/ && $state =~ /^1$|^0$|^$/ && $akt =~ /^1$|^0$|^$/ && $prov_id =~ /^\d+$|^$/ && $con_type_id =~ /^\d+$|^$/ && $ats_id =~ /^\d+$/ && $pilot =~ /^1$|^0$|^$/ && $tarif_id =~ /^\d+$/ && $vpivci =~ /^\d+\/\d+$/ && $pppoe =~ /^1$|^0$|^$/)
    {
      if (!$prov_id){$prov_id=0}
      if (!$ats_eq_id){$ats_eq_id=0}
      $select = "INSERT into $schema.ats_eq_ports(ats_eq_id,ip,inst_date,school_id,phone,state,akt,prov_id,con_type_id,ats_id,slot,port,pilot,tarif_id,vpivci,pppoe)
		 VALUES(''$ats_eq_id'',''$ip'',to_date(''$date'',''YYYY-MM-DD''),''$school_id'',''$phone'',''$state'',''$akt'',''$prov_id'',''$con_type_id'',''$ats_id'',''$slot'',''$port'',''$pilot'',''$tarif_id'',''$vpivci'',''$pppoe'')";
      $query = "BEGIN
		  IRONLEG.ats_eq_ports_insert('$select','$connectors_list','add','0');
		END;";
      $redirect = "?action=add_connect&school_id=$school_id&ats_eq_id=$ats_eq_id&ip=$ip&inst_date=$date&slot=$slot&port=$port&phone=$phone&state=$state&akt=$akt&prov_id=$prov_id&con_type_id&vpivci=$vpivci&date=$date&connectors_list=$connectors_list&city_id=$city_id&ats_id=$ats_id";
      &add_edit_del_db($query,$redirect,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit_connect")
  {
    if ($school_id =~ /^\d+$/ && $ats_eq_ports_id =~ /^\d+$|^$/)
    {
      &add_edit_connect_form($action,$school_id,$ats_eq_ports_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit_connect_db")
  {

    if ($ats_eq_ports_id =~ /^\d+$/ && $ats_eq_id =~ /^\d+$|^$/ && $ip =~ /^\d+\.\d+\.\d+\.\d+$/ && $date =~ /^\d{4}-\d{2}-\d{2}$/i && $slot =~ /^\d+$|^$/ && $port =~ /^\d+$|^$/ && $school_id =~ /^\d+$/ && $phone =~ /^\d{5,7}$/ && $state =~ /^1$|^0$|^$/ && $akt =~ /^1$|^0$|^$/ && $prov_id =~ /^\d+$|^$/ && $con_type_id =~ /^\d+$|^$/ && $ats_id =~ /^\d+$/ && $pilot =~ /^1$|^0$|^$/ && $tarif_id =~ /^\d+$/ && $vpivci =~ /^\d+\/\d+$/ && $pppoe =~ /^1$|^0$|^$/)
    {
      if (!$prov_id){$prov_id=0}
      if (!$ats_eq_id){$ats_eq_id=0}
      $select = "UPDATE $schema.ats_eq_ports
		  SET ats_eq_id = ''$ats_eq_id'',
		      ip = ''$ip'',
		      inst_date = to_date(''$date'',''YYYY-MM-DD''),
		      school_id =''$school_id'',
		      phone = ''$phone'',
		      state = ''$state'',
		      akt = ''$akt'',
		      slot = ''$slot'',
		      port = ''$port'',
		      pilot = ''$pilot'',
		      ats_id = ''$ats_id'',
		      prov_id = ''$prov_id'',
		      con_type_id = ''$con_type_id'',
		      tarif_id = ''$tarif_id'',
		      vpivci = ''$vpivci'',
		      pppoe = ''$pppoe''
		  WHERE id = ''$ats_eq_ports_id''";
      $query = "BEGIN
		  IRONLEG.ats_eq_ports_insert('$select','$connectors_list','edit','$ats_eq_ports_id');
		END;";
      $redirect = "?action=edit_connect&school_id=$school_id&ats_eq_ports_id=$ats_eq_ports_id";
      &add_edit_del_db($query,$redirect,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "delete_connect")
  {
    if ($school_id =~ /^\d+$/ && $ats_eq_ports_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$connect_table WHERE id='$ats_eq_ports_id'";
      $redirect = "?school_id=$school_id";
      &add_edit_del_db($query,$redirect,$school_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "vpn")
  {
    print "<td valign='top' width=50%>VPN:<br>";
      if ($ats_eq_ports_id =~ /^\d+$/ && $school_id =~ /^\d+$/ && $vpn_user !~ /[\'\\\"]/i && $vpn_pass !~ /[\'\\\"]/i)
      {
	  my $sql0 = $db->prepare("SELECT ip,school_id
				   FROM $schema.$connect_table
				   WHERE id = '$ats_eq_ports_id'");
	  $sql0->execute;
	  ($ip,$school_id) = $sql0->fetchrow_array;
	print "<form method='post' onsubmit='return checkForm(this);'>";
	print "<table width='50%' border='1' cellspacing='1' cellpadding='1' align='left'>";
	if ($action2 eq 'submit')
	{
	  if ($vpn == 1)
	  {
	    my $sth = $dbh2->prepare("SELECT username
				      FROM radreply
				      WHERE value='$ip'
				      AND attribute='Framed-IP-Address'");
	    $sth->execute;
	    $reply_user = $sth->fetchrow_array;
	    $d = "disabled";
	    
	    my $sth = $dbh2->prepare("SELECT username
				      FROM radcheck
				      WHERE username = '$vpn_user'");
	    $sth->execute;
	    $check_user = $sth->fetchrow_array;
    
	      if ($reply_user eq '' && $check_user eq '')
	      {
	      my $sth = $dbh2->prepare("INSERT into radreply(username,attribute,op,value)
					VALUES('$vpn_user','Framed-IP-Address','==','$ip')");
	      $sth->execute;
	      my $sth = $dbh2->prepare("INSERT into radcheck(username,attribute,op,value)
					VALUES('$vpn_user','Cleartext-Password',':=','$vpn_pass')");
	      $sth->execute;
	      my $sth = $dbh2->prepare("INSERT into usergroup(username,groupname,priority)
					VALUES('$vpn_user','VPN 3G','1')");
	      $sth->execute;
	      }
	      else
	      {
		print "<SCRIPT LANGUAGE='javascript'>
		<!--
		  alert('Bad Username.');
		  document.location.href='schools_info.pl?action=vpn&school_id=$school_id&ats_eq_ports_id=$ats_eq_ports_id';
		//-->   
		</SCRIPT>";
	      }
	    $ch="checked";
	  }
	  else
	  {
	    my $sth = $dbh2->prepare("DELETE
				      FROM radreply
				      WHERE username = '$vpn_user'
				      AND value='$ip'
				      AND attribute='Framed-IP-Address'");
	    $sth->execute;
	    my $sth = $dbh2->prepare("DELETE
				      FROM radcheck
				      WHERE username = '$vpn_user'
				      AND attribute='Cleartext-Password'");
	    $sth->execute;
	    $vpn_user='';
	    $vpn_pass='';
	  }
	}
	else
	{
	  my $sth = $dbh2->prepare("SELECT username
				    FROM radreply
				    WHERE value='$ip'
				    AND attribute='Framed-IP-Address'");
	  $sth->execute;
	  $r_user = $sth->fetchrow_array;
	    if ($r_user)
	    {
	      $d="disabled";
	      my $sth = $dbh2->prepare("SELECT value
					FROM radcheck
					WHERE username = '$r_user'
					AND attribute = 'Cleartext-Password'");
	      $sth->execute;
	      $vpn_pass = $sth->fetchrow_array;
	      $vpn_user=$r_user;$vpn=1;$ch="checked";
	    }      
	}
	print "<tr><td width='50%'>Enable VPN: <td><input type=checkbox name='vpn' value=1 $ch>";
	print "<tr><td width='50%'>IP: <td>$ip";
	  if ($d eq "disabled")
	  {
	    print "<input type=hidden name='vpn_user' value='$vpn_user'>";
	    print "<input type=hidden name='vpn_pass' value='$vpn_pass'>";
	  }
	print "<tr><td width='50%'>VPN Username: <td><input type=text name='vpn_user' value='$vpn_user' $d>";    
	print "<tr><td width='50%'>VPN Password: <td><input type=text name='vpn_pass' value='$vpn_pass' $d>";
	print "<input type=hidden name='action' value='vpn'>";
	print "<input type=hidden name='action2' value='submit'>";
	print "<input type=hidden name='ats_eq_ports_id' value='$ats_eq_ports_id'>";
	print "<input type=hidden name='school_id' value='$school_id'>";
	print "<tr><td> &nbsp; <a href='schools_info.pl?school_id=$school_id'>Back</a><td><input type=submit>";
	print "</table>";
	print "</table>";
      print "<script>
		function checkForm(obj){
		      var reg_ip = /\^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\$\|\^\$/i;
		      var reg_exp = /[()\%\'\*]/;
		      var reg_date = /\^([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})\$/i;
		      var reg_mac = /\^\\w{12}\$\|\^\$/i;
		      
			  if (obj.vpn.value == '1')
			  {
			    if (obj.vpn_user.value == '')
			    {
			      alert ('Please enter VPN username.');
			      return false;
			    }
			    if (obj.vpn_pass.value == '')
			    {
			      alert ('Please enter VPN password.');
			      return false;
			    }
			  }
		    }
		      
	       </script>";
        }
      else
      {
	print "Error";
      }
  }
  
sub add_edit_eq_form
{
  my($action,$school_id,$se_id) = @_;
  print "<td valign='top' width=50%>";
      if ($se_id ne "")
      {
	  my $sql0 = $db->prepare("SELECT eq_id, eq_name, type_id, type_name, eq_desc, ip, mac, serial, imei, to_char(inst_date,'YYYY-MM-DD'), con_id, int_akt, moe_akt, connected
				   FROM $schema.$eq_table
				   WHERE id = :se_id");
          $sql0->bind_param(":se_id",$se_id);
	  $sql0->execute;
	  ($eq_id, $eq_name,$eq_type_id,$eq_type,$eq_desc, $eq_ip,$eq_mac,$eq_serial,$eq_imei,$date,$con_id,$int_akt,$moe_akt,$connected) = $sql0->fetchrow_array;
      }
  if ($se_id_new ne ""){$se_id = $se_id_new}


    if (!$eq_type_id)
    {
      my $sql0 = $db->prepare("SELECT c.*
			       FROM (SELECT id,name
				     FROM $schema.select_equipments_type_v
				     ORDER BY name) c
			       WHERE rownum <= 1");
      $sql0->execute;
      ($eq_type_id) = $sql0->fetchrow_array;
    }

  print "<form name='select' action='schools_info.pl' method='get' onsubmit='return checkForm(this);'>";
  print "<table width='50%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Equipment Type:";
  print "<td><select 
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
  my $sql0 = $db->prepare("SELECT id,name
			   FROM $schema.select_equipments_type_v
			   ORDER BY name");
  $sql0->execute;
      while (my($id,$type) = $sql0->fetchrow_array)
      {
	  if ($eq_type_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='schools_info.pl?action=$action&eq_type_id=$id&se_id_new=$se_id&school_id=$school_id&eq_ip=$eq_ip&eq_serial=$eq_serial&eq_imei=$eq_imei&eq_mac=$eq_mac&con_id=$con_id&date=$date&int_akt=$int_akt&moe_akt=$moe_akt' $sl>$type</option>";
      }
  print "</select>";

      if ($eq_id eq "")
      {
      my $sql0 = $db->prepare("SELECT description, id
			       FROM $schema.select_eq_man_v
			       WHERE type_id = :eq_type_id
			       AND ROWNUM<=1");
      $sql0->bind_param(":eq_type_id",$eq_type_id);
      $sql0->execute;
      ($eq_desc,$eq_id) = $sql0->fetchrow_array;
      }


  print "<tr><td>Equipment:";
  print "<td><select 
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
  my $sql0 = $db->prepare("SELECT id,eq_name,man_name,description
			   FROM $schema.select_eq_man_v
			   WHERE type_id = :eq_type_id
			   ORDER BY man_name");
  $sql0->bind_param(":eq_type_id",$eq_type_id);
  $sql0->execute;
      while (my($id,$eq,$man_name,$eq_desc) = $sql0->fetchrow_array)
      {
	  if ($eq_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='schools_info.pl?action=$action&eq_type_id=$eq_type_id&se_id_new=$se_id&school_id=$school_id&eq_desc=$eq_desc&eq_id=$id&eq_serial=$eq_serial&eq_ip=$eq_ip&eq_imei=$eq_imei&eq_mac=$eq_mac&con_id=$con_id&date=$date&int_akt=$int_akt&moe_akt=$moe_akt' $sl>$man_name $eq</option>";
      }
  print "</select>";

  print "<tr valign=top><td>Description<td>$eq_desc";
  print "<tr><td>IP Address<td><input type='text' name='eq_ip' value='$eq_ip'>";
  print "<tr><td>Mac Address<td><input type='text' name='eq_mac' value='$eq_mac'>";
  print "<tr><td>Serial Number<td><input type='text' name='eq_serial' value='$eq_serial'>";
  print "<tr><td>IMEI<td><input type='text' name='eq_imei' value='$eq_imei'>";
  print "<tr><td>Date: <td><input type='text' name='date' value='$date'>";
  print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
  print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
  
  print "<tr><td>Connector:<td><select name='con_id'>";

  my $sql0 = $db->prepare("SELECT id,name
			   FROM $schema.select_connectors_v");
  $sql0->execute;
      while (my($id,$name) = $sql0->fetchrow_array)
      {
	  if ($con_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='$id' $sl>$name</option>";
      }
  print "</select>";
      if ($connected == 1){$ch="checked"}
      else{$ch=""}
  print "<tr><td>Connected:<td><input type='checkbox' name='connected' value='1' $ch>";
      if ($int_akt == 1){$ch="checked"}
      else{$ch=""}
  print "<tr><td>Internal AKT:<td><input type='checkbox' name='int_akt' value='1' $ch>";
      if ($moe_akt == 1){$ch="checked"}
      else{$ch=""}
  print "<tr><td>MoE AKT:<td><input type='checkbox' name='moe_akt' value='1' $ch>";
  
  print "<input type='hidden' name='se_id' value='$se_id'>";
  print "<input type='hidden' name='eq_id' value='$eq_id'>";
  print "<input type='hidden' name='school_id' value='$school_id'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<tr><td colspan=2><input type='submit'>";
  print "</table>";
  print "</form>";
  print "<script>
	    function checkForm(obj){
		  var reg_ip = /\^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\$\|\^\$/i;
		  var reg_exp = /[()\%\'\*]/;
		  var reg_date = /\^([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})\$/i;
		  var reg_mac = /\^\\w{12}\$\|\^\$/i;
		  
		      if (obj.date.value == '')
		      {
			  alert ('Please enter installation date.');
			  return false;
		      }
		      else
		      {
			if (reg_date.exec(obj.date.value) == null)
			{
			  alert ('Please enter right installation date.');
			  return false;
			}
		      }
		      if (reg_ip.exec(obj.eq_ip.value) == null)
		      {
		      alert ('Please enter right IP.');
		      return false;
		      }
		      if (reg_mac.exec(obj.eq_mac.value) == null)
		      {
		      alert ('Please enter right MAC.');
		      return false;
		      }
		      if (reg_exp.exec(obj.eq_serial.value) != null)
		      {
		      alert ('Please enter right serial.');
		      return false;
		      }
		}
  
		  
	   </script>";

}

sub add_edit_connect_form
{
my($action,$school_id,$ats_eq_ports_id) = @_;
    if ($action eq "edit_connect" && $ats_eq_ports_id ne "")
    {
      $select = "SELECT city_id,to_char(inst_date,'YYYY-MM-DD'),ip,ats_id, ats_name,eq_id,eq_name,slot,port,phone,state,akt,pilot,prov_id,con_type_id,tarif_id,vpivci,pppoe
		 FROM $schema.$connect_table
		 WHERE id = :ats_eq_ports_id";
      my $sql0 = $db->prepare("$select");
      $sql0->bind_param(":ats_eq_ports_id",$ats_eq_ports_id);
      $sql0->execute;
      ($city_id,$date,$ip,$ats_id,$ats,$ats_eq_id,$ats_eq_name,$slot,$port,$phone,$state,$akt,$pilot,$prov_type, $con_type_id,$tarif_id,$vpivci,$pppoe) = $sql0->fetchrow_array;
      my $sql2 = $db->prepare("SELECT eq_count
			       FROM $schema.select_ats_v
			       WHERE id=:ats_id
			       AND rownum <=1");
      $sql2->bind_param(":ats_id",$ats_id);
      $sql2->execute;
      $eq_count = $sql2->fetchrow_array;

      print "$prov_type";
    }
    if ($ats_eq_ports_id_new ne ""){$ats_eq_ports_id = $ats_eq_ports_id_new}
    print "<form name='select' action='schools_info.pl' method='get' onsubmit='return func3(this);'>";
    print "<td valign='top' width=50%>Add ATS Equipment:<br>";
    print "<table  width='50%' border='1' cellspacing='1' cellpadding='1' align='left'>";

#########################
#	SELECT CITY	#
#########################

	if ($city_id eq '')
	{
	    my $sql2 = $db->prepare("SELECT id
				     FROM $schema.select_city_v
				     WHERE rownum <=1");
	    $sql2->execute;
	    $city_id = $sql2->fetchrow_array;
	}

    print "<tr><td width='50%'>City:";
    print "<td><select 
		onchange=\"if (this.options[this.selectedIndex].value == '') 
		this.selectedIndex=0; 
		else window.open(this.options[this.selectedIndex].value,'_top')\">";
    my $sql0 = $db->prepare("SELECT id,name
			     FROM $schema.select_city_v");
    $sql0->execute;
    

	
	while (my($id,$city) = $sql0->fetchrow_array)
	{
		if ($city_id eq $id){$sl = "selected"}
		else {$sl = ""}
	    print "<option value='schools_info.pl?action=$action&ats_eq_ports_id_new=$ats_eq_ports_id&city_id=$id&school_id=$school_id&date=$date&slot=$slot&port=$port&phone=$phone&ip=$ip&akt=$akt&pilot=$pilot&state=$state&prov_type=$prov_type&con_type_id=$con_type_id&tarif_id=$tarif_id&vpivci=$vpivci&connectors_list=$connectors_list' $sl>$city</option>";
	}
    print "</select>";

	if ($ats_id eq '')
	{
	    my $sql2 = $db->prepare("SELECT id,eq_count
				     FROM $schema.select_ats_v
				     WHERE city_id=:city_id
				     AND rownum <=1");
            $sql2->bind_param(":city_id",$city_id);
	    $sql2->execute;
	    ($ats_id,$eq_count) = $sql2->fetchrow_array;
	}

#########################
#	SELECT ATS	#
#########################

    print "<tr><td>ATS:";
    print "<td><select 
		onchange=\"if (this.options[this.selectedIndex].value == '') 
		this.selectedIndex=0; 
		else window.open(this.options[this.selectedIndex].value,'_top')\">";
    my $sql0 = $db->prepare("SELECT id,name,eq_count
			     FROM $schema.select_ats_v
			     WHERE city_id = :city_id");
    $sql0->bind_param(":city_id",$city_id);
    $sql0->execute;
	while (my($id,$ats,$eq_count) = $sql0->fetchrow_array)
	{
		if ($ats_id eq $id){$sl = "selected"}
		else {$sl = ""}
#		if ($eq_count == 0){$prov_type_new = 2}
#		else {$prov_type_new = 0}
	    print "<option value='schools_info.pl?action=$action&ats_eq_ports_id_new=$ats_eq_ports_id&city_id=$city_id&school_id=$school_id&ats_id=$id&date=$date&slot=$slot&port=$port&phone=$phone&ip=$ip&akt=$akt&pilot=$pilot&state=$state&eq_count=$eq_count&prov_type=$prov_type&con_type_id=$con_type_id&tarif_id=$tarif_id&vpivci=$vpivci&connectors_list=$connectors_list' $sl>$ats</option>";
	}
    print "</select>";

#################################
#	SELECT PROVIDER		#
#################################

    print "<tr><td valign='top'>Provider: ";
	if($eq_count eq "0"){$ch="checked";$dis="disabled";$prov_type=1}
#	elsif($prov_type == 0){}
	elsif ($prov_type > 0){$ch="checked"}
	else{$ch="";$dis=""}
    print "<td><input type='radio' name='prov_type' value='0' $dis checked onclick=\"window.open('schools_info.pl?action=$action&ats_eq_ports_id_new=$ats_eq_ports_id&city_id=$city_id&school_id=$school_id&ats_id=$ats_id&prov_type=0&eq_count=$eq_count&date=$date&slot=$slot&port=$port&phone=$phone&ip=$ip&akt=$akt&pilot=$pilot&state=$state&con_type_id=$con_type_id&tarif_id=$tarif_id&vpivci=$vpivci&connectors_list=$connectors_list','_top')\">AzEduNet";
    print "<br><input type='radio' name='prov_type' value='1' $ch onclick=\"window.open('schools_info.pl?action=$action&ats_eq_ports_id_new=$ats_eq_ports_id&city_id=$city_id&school_id=$school_id&ats_id=$ats_id&prov_type=1&eq_count=$eq_count&date=$date&slot=$slot&port=$port&phone=$phone&ip=$ip&akt=$akt&pilot=$pilot&state=$state&con_type_id=$con_type_id&tarif_id=$tarif_id&vpivci=$vpivci&connectors_list=$connectors_list','_top')\">Other";

	if ($prov_type == 0 && $eq_count > 0)
	{
	    print "<tr><td>ATS Equipment:<td><select name='ats_eq_id'>";
	    my $sql1 = $db->prepare("SELECT id, man_name, eq_name
				     FROM $schema.select_ats_eq_man_v
				     WHERE ats_id = :ats_id");
            $sql1->bind_param(":ats_id",$ats_id);
	    $sql1->execute;
		while (my($id,$man_name,$ats_eq) = $sql1->fetchrow_array)
		{
		    if ($ats_eq_id eq $id){$sl="selected"}
		    else{$sl=""}
		    print "<option value='$id' $sl>$man_name $ats_eq</option>";
		}
	    print "</select>";
	}
	elsif ($prov_type > 0)
	{
	    print "<tr><td>Provider:<td><select name='prov_id'>";
	    my $sql1 = $db->prepare("SELECT id,name
				     FROM $schema.select_provider_v");
	    $sql1->execute;
		while (my($id,$name) = $sql1->fetchrow_array)
		{
		if ($prov_type eq $id){$sl="selected"}
		else{$sl=""}
		print "<option value='$id' $sl>$name</option>";
		}
	    print "</select>";
	}

#################################
#	SELECT CONNECTION TYPE	#
#################################

    print "<tr><td>Connection Type:<td><select name='con_type_id'>";
    my $sql1 = $db->prepare("SELECT id,name
			     FROM $schema.select_con_type_v");
    $sql1->execute;
	while (my($id,$name) = $sql1->fetchrow_array)
	{
	if ($con_type_id eq $id){$sl="selected"}
	else{$sl=""}
	print "<option value='$id' $sl>$name</option>";
	}
    print "</select>";

    print "<tr><td>VPI/VCI: <td><input type='text' name='vpivci' value='$vpivci'>";

#################################
#	SELECT TARIFS		#
#################################

    print "<tr><td>Tarif:<td><select name='tarif_id'>";
    my $sql1 = $db->prepare("SELECT id,name
			     FROM $schema.select_tarifs_v");
    $sql1->execute;
	while (my($id,$name) = $sql1->fetchrow_array)
	{
	if ($tarif_id eq $id){$sl="selected"}
	else{$sl=""}
	print "<option value='$id' $sl>$name</option>";
	}
    print "</select>";


	if ($pilot == 1){$ch="checked"}
	else{$ch=""}
    print "<tr><td>Pilot school: <td><input type='checkbox' name='pilot' value='1' $ch>";
	if ($pppoe == 1){$ch="checked"}
	else{$ch=""}
    print "<tr><td>PPPoE Client: <td><input type='checkbox' name='pppoe' value='1' $ch>";
    
	if ($prov_type == 0)
	{
	    print "<tr><td>Slot:<td><input type='text' name='slot' value='$slot'>";
	    print "<tr><td>Port:<td><input type='text' name='port' value='$port'>";
	}
    print "<tr><td>Phone:<td><input type='text' name='phone' value='$phone'>";
    print "<tr><td>IP Address:<td><input type='text' name='ip' value='$ip'>";
    print "<tr><td>Date: <td><input type='text' name='date' value='$date'>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.select.date);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
	if ($akt == 1){$ch="checked"}
	else{$ch=""}
    print "<tr><td>AKT:<td><input type='checkbox' name='akt' value='1' $ch>";
#	    if ($support == 1){$ch="checked"}
#	    else{$ch=""}
#	print "<tr><td>Support:<td><input type='checkbox' name='support' value='1' $ch>";
    print "<tr><td>State:<td><select name='state'>";
	if ($state == 0){$sl="selected"}
	else{$sl=""}
    print "<option value='1'>Connected</option>";
    print "<option value='0' $sl>Not Connected</option>";
    print "</select>";
    print "<tr><td valign=top>Connectors:<td><select name='select' size='4' width='100%'>";
    
      if ($connectors_list ne '')
      {
	while ($connectors_list =~ /(.+?)\@/g)
	{
	$connector_name=$1;
	$connector_name=$1;
	print "<option value='$connector_name'>$connector_name</option>";
	}
      }
		
      if ($action eq "edit_connect")
      {
      my $sql2 = $db->prepare("select $schema.schools_connectors(:ats_eq_ports_id) from dual");
      $sql2->bind_param(":ats_eq_ports_id",$ats_eq_ports_id);
      $sql2->execute;
      $cursor = $sql2->fetchrow_array;
	while ( $con_name = $cursor->fetchrow_array )
	{
	  print "<option value='$con_name'>$con_name <br>";
	}
      }
    print "</select>";
    
    print "<tr><td>&nbsp<td><select name='connector'>";
    my $sql1 = $db->prepare("SELECT name
			     FROM $schema.select_connectors_v");
    $sql1->execute;
	while (my($name) = $sql1->fetchrow_array)
	{
	    print "<option value='$name'>$name</option>";
	}
    print "</select>";
    print "<tr><td>&nbsp<td><input type='button' value='Add' onclick='func(this.form);'><input type='button' value='Delete' onclick='func2(this.form)'>";
    $action .= "_db";
    print "<input type='hidden' name='action' value='$action'>";
    print "<input type='hidden' name='school_id' value='$school_id'>";
    print "<input type='hidden' name='ats_id' value='$ats_id'>";
    print "<input type='hidden' name='city_id' value='$city_id'>";
  #  print "<input type='hidden' name='ats_eq_id' value='$ats_eq_id'>";
    print "<input type='hidden' name='ats_eq_ports_id' value='$ats_eq_ports_id'>";
    print "<input type='hidden' name='connectors_list'>";
    print "<tr><td colspan=2><input type='submit'>";
    print "</table>";
    print "</form>";
    print "<script type='text/javascript'>
      function func(obj){
	    var exist = 0;
		if (obj.connector.value != '')
		{
		    for (var i=0; i < obj.select.length; i++)
		    {
			if (obj.connector.value == obj.select.options[i].value)
			{
			    alert('Connector ' + obj.connector.value + ' already added.');
			    exist = 1;
			}
		    }
		    if (exist == 0)
		    {
			obj.select.options[obj.select.length] = new Option(obj.connector.value);
		    }
		}
	    }
      function func2(obj){
		    if (obj.select.selectedIndex >= 0)
		    {
			obj.select.options[obj.select.selectedIndex] = null;
		    }
		    else
		    {
			obj.select.options[0] = null;
		    }
	    }
      function func3(obj){
		  var reg_vpivci = /\^([0-9]\+)\\\/([0-9]\+)\$/i;
		  var reg_phone = /\^[0-9]{5\,7}\$/i;
		  var reg_ip = /\^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\$/i;
		  var reg_exp = /[()\%\'\*]/;
		  var reg_date = /\^([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})\$/i;
			    for (var i=0; i < obj.select.length; i++)
			    {
			    obj.connectors_list.value += obj.select.options[i].value + '\@';
			    }
		    if (obj.vpivci.value == '')
		    {
			alert('Please enter vpi/vci. ');
			return false;
		    }
		    else
		    {
		      if (reg_vpivci.exec(obj.vpivci.value) == null)
		      {
		      alert ('Please enter right vpi/vci.');
		      return false;
		      }
		    }
		    if (obj.phone.value == '')
		    {
			alert('Please enter phone number.');
			return false;
		    }
		    else
		    {
		      if (reg_phone.exec(obj.phone.value) == null)
		      {
		      alert ('Please enter right phone number.');
		      return false;
		      }
		    }
		    if (obj.ip.value == '')
		    {
			alert('Please enter IP address.');
			return false;
		    }
		    else
		    {
		      if (reg_ip.exec(obj.ip.value) == null)
		      {
		      alert ('Please enter right ip.');
		      return false;
		      }		      
		    }
		    if (obj.date.value == '')
		    {
			alert('Please enter date.');
			return false;
		    }
		    else
		    {
		      if (reg_date.exec(obj.date.value) == null)
		      {
		      alert ('Please enter right date.');
		      return false;
		      }		      
		    }
		    if (obj.select.length < 1)
		    {
			alert('Please choose connectors.');
			return false;
		    }

	    }		
	</script>
    ";
}	



sub add_edit_del_db
{
  my ($query,$redirect,$school_id) = @_;
  print "$school_id";
  $sql0=$db->prepare($query);
    if ($sql0->execute)
    {
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='?school_id=$school_id';
	       //-->   
	     </SCRIPT>";
    }
    else
    {
    $error = $db->errstr;
    $error =~ /ORA-(\d+)/;
    $error = "Error ORA-$1";
      if ($1 == 1)
      {
	$error = "Manufacturer already exist.";
      }
	print "<SCRIPT LANGUAGE='javascript'>
		<!--
		  alert('$error');
		  document.location.href='$redirect';
		//-->   
		</SCRIPT>";
    }  
}

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

sub snmp_change_tariff
{
=d
    my name
=cut
}

sub snmp_fetch_data
{
   
    my $zyxel_type;
    
    my ($session, $error) = Net::SNMP->session(
	-hostname  => $a_ip,
	-community => $community,
	-timeout   => $snmp_timeout ,
	);

    if (!defined $session) {
	printf " ne podnalas ERROR: %s.\n", $error;
	    return 0;
    }



    if (int($g_slot) >= 3)
    {#then we have ies-5000
	$snmp_port = int($g_slot).($g_port);
	$zyxel_type = '5000+';
    }
    else
    {
	$snmp_port = int($g_port);
	$zyxel_type = '1000+';
    }
    
    
    $port_status =  $session->get_request(-varbindlist => [ $snmp_port_enable_disable_prefix.$snmp_port],);
    ($_,$port_status) = %$port_status;
    if ($port_status == 1) { $port_status = 'Enabled/Включен'} else { $port_status = 'Disabled/ВЫключен'};
    if (!($port_status)) {         printf "ERROR: %s.\n", $session->error(); }

    #getting SNR params.
    #for ies-5000
    if ($zyxel_type eq '5000+')
    {
	$snr_upstream =  $session->get_request(-varbindlist => [ $snmp_ies5000_snr_upstream.$snmp_port],);
	($_,$snr_upstream) = %$snr_upstream;
	$snr_downstream = $session->get_request(-varbindlist => [$snmp_ies5000_snr_downstream.$snmp_port] ,); 
	($_,$snr_downstream) = %$snr_downstream;

    }
    else
    {
	$snr_upstream =  $session->get_request(-varbindlist => [ $snmp_snr_upstream.$snmp_port],);
	($_,$snr_upstream) = %$snr_upstream;
	$snr_downstream = $session->get_request(-varbindlist => [$snmp_snr_downstream.$snmp_port] ,); 
	($_,$snr_downstream) = %$snr_downstream;
    }

    #getting download,upload and annexm parameters
    $download_rate = $session->get_request(-varbindlist => [$snmp_adslCurrentInSpeed.$snmp_port] ,);
    ($_,$download_rate ) = %$download_rate;
    #removing last 3 characters
    $download_rate =~ s/\d{3}$//;
    
    $upload_rate = $session->get_request(-varbindlist => [$snmp_adslCurrentOutSpeed.$snmp_port] ,);
    ($_,$upload_rate ) = %$upload_rate;
    #removing last 3 characters
    $upload_rate =~ s/\d{3}$//;


    $max_download_rate = $session->get_request(-varbindlist => [$snmp_adslAttainableInRate.$snmp_port] ,);
    ($_,$max_download_rate ) = %$max_download_rate;
    #removing last 3 characters
    $max_download_rate =~ s/\d{3}$//;


    $max_upload_rate = $session->get_request(-varbindlist => [$snmp_adslAttainableOutRate.$snmp_port] ,);
    ($_,$max_upload_rate ) = %$max_upload_rate;
    #removing last 3 characters
    $max_upload_rate =~ s/\d{3}$//;


    $adsl_ifInErrors = $session->get_request(-varbindlist => [$snmp_ifInErrors.$snmp_port] ,);
    ($_,$adsl_ifInErrors ) = %$adsl_ifInErrors;
    
    $adsl_ifOutErrors = $session->get_request(-varbindlist => [$snmp_ifOutErrors.$snmp_port] ,);
    ($_,$adsl_ifOutErrors ) = %$adsl_ifOutErrors;


    $adsl_ifInDiscards = $session->get_request(-varbindlist => [$snmp_ifInDiscards.$snmp_port] ,);
    ($_, $adsl_ifInDiscards ) = %$adsl_ifInDiscards;

    $adsl_ifOutDiscards = $session->get_request(-varbindlist => [$snmp_ifOutDiscards.$snmp_port] ,);
    ($_, $adsl_ifInDiscards) = %$adsl_ifOutDiscards;

    #fetching annexm according the DSLAM model
    if ($zyxel_type eq '5000+')
    {
	$adsl_annexm = $session->get_request(-varbindlist => [$snmp_adslAnnexM_ies5000.$snmp_port] ,);
	($_, $adsl_annexm) = %$adsl_annexm;
    }
    
    if ($zyxel_type eq '1000+')
    {
	$adsl_annexm = $session->get_request(-varbindlist => [ $snmp_adslAnnexM_ies1248.$snmp_port] ,);
	($_, $adsl_annexm) = %$adsl_annexm;
    }
    
    

    if ($adsl_annexm == 2) { $adsl_annexm ='off' ;} 
    if ($adsl_annexm == 1) { $adsl_annexm ='on' ;}
    
    #getting profile with speed on the port
    $actual_profile = $session->get_request(-varbindlist => [$snmp_profile_change_prefix.$snmp_port] ,);
    ($_,$actual_profile ) = %$actual_profile;


    if ( $snr_downstream >= 290  ) 
    {
	$line_quality = 'Отличная линия.Может поддержать и VDSL2+ ';
    }
    if ( $snr_downstream >= 200 and $snr_downstream < 290  ) 
    {
	$line_quality = 'Очень хорошая линия ';
    }
    if ( $snr_downstream >= 100 and $snr_downstream < 200  ) 
    {
	$line_quality = 'Средний уровень линии,без проблем с синхронизацией';
    }
    if ( $snr_downstream < 100 and $snr_downstream > 70  ) 
    {
	$line_quality = 'Возможны сбои';
    }
    if ( $snr_downstream < 70 ) 
    {
	$line_quality = 'Очень плохая линия, присутствуют проблемы синхронизации';
    }
    
    if ($snr_downstream == 0 )
    {	
	$snr_downstream = $snr_upstream = 'Порт не в онлайне';
	$line_quality = 'Порт не в онлайне';
    }

    return 1;
}


sub mac_from_dhcp_requests($)
{
	  my $mac= shift;
	  if ($mac eq '') 
	  {
		  print "<tr> No info in dhcp requests database";
	  }
	  else 
	  {
	    my $sql0=$db->prepare(qq{select to_char(req_date,'DD/MM/YYYY HH24:MI:SS'),slot,port,mac,
				      remote_ip,ip from IRONLEG.dhcp_requests_v where upper(regexp_replace(mac,':'))=:mac });
	    $sql0->bind_param(":mac",$mac);
	    $sql0->execute();
	    my ($req_date,$slot,$port,$mac_addr,$remote_ip,$own_ip) = $sql0->fetchrow_array();
	    print "<tr colspen=40>
		  <td><b>Date</b></td>
		  <td><b>slot</b></td>
		  <td><b>port</b></td>
		  <td><b>gw_ip</b></td>
		  <td><b>ip</b></td>
		  </tr>
		  <tr>
		    <td>$req_date</td>
		    <td>$slot</td>
		    <td>$port</td>
		    <td>$remote_ip</td>
		    <td>$own_ip</td></tr>";
	  }
}
	
