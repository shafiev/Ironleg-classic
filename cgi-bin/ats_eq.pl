#!/usr/bin/perl

use DBI;
use DBD::Oracle;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);


my $action=param('action');
my $ats_eq_id=param('ats_eq_id');
my $ats_eq_id_new=param('ats_eq_id_new');
my $eq_id=param('eq_id');
my $eq_desc=param('eq_desc');
my $ats_id=param('ats_id');
my $city_id=param('city_id');
my $eq_id_new=param('eq_id_new');
my $eq_name=param('eq_name');
my $serial=param('serial');
my $type_id=param('type_id');
my $type_name=param('type_name');
my $man_id=param('man_id');
my $mac=param('mac');
my $ip=param('ip');
my $ports=param('ports');
my $date=param('date');
my $con_id=param('con_id');

my $s_city_name=param('s_city_name');
my $s_ats_name=param('s_ats_name');
my $s_type_name=param('s_type_name');
my $s_man_name=param('s_man_name');
my $s_eq_name=param('s_eq_name');
my $s_ip=param('s_ip');
my $s_serial=param('s_serial');
my $s_mac=param('s_mac');
my $s_con_name=param('s_con_name');

my $page=param('page');
my $rows=param('rows');



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
$table="ats_eq_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";

$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass, {ora_charset => 'AL32UTF8'});
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
    
#print "$privs_list";

  if ($action eq "")
  {
    if ($s_city_name !~ /['\\]/i && $s_ats_name !~ /['\\]/i && $s_type_name !~ /['\\]/i && $s_man_name !~ /['\\]/i && $s_eq_name !~ /['\\]/i && $s_ip !~ /['\\]/i && $s_serial !~ /['\\]/i && $s_mac !~ /['\\]/i && $s_con_name !~ /['\\]/i)
    {
      if ($privs_list =~ /SELECT/)
      {
      print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<tr><th>N
		     <th>City
		     <th>ATS
		     <th>Type
		     <th>Manufacturer
		     <th>Equipment Name
		     <th>IP Address
		     <th>Equipment Serial
		     <th>Mac Address
		     <th>Ports
		     <th>Used Ports
                     <th>Left Ports
		     <th>Connector
		     <th>Date
		     <th>&nbsp;
		 </tr>";
      print "<form method=post>";
      print "<tr valign=top><td>&nbsp;</td>
			    <td><input name='s_city_name' value='$s_city_name' size='8'></td>
			    <td><input name='s_ats_name' value='$s_ats_name' size='23'></td>
			    <td><input name='s_type_name' value='$s_type_name' size='8'></td>
			    <td><input name='s_man_name' value='$s_man_name' size='11'></td>
			    <td><input name='s_eq_name' value='$s_eq_name' size='13'></td>
			    <td><input name='s_ip' value='$s_ip' size='10'></td>
			    <td><input name='s_serial' value='$s_serial' size='14'></td>
			    <td><input name='s_mac' value='$s_mac' size='10'></td>
			    <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>
			    <td><input name='s_con_name' value='$s_con_name' size='8'></td>
			    <td colspan=2><input type=submit></td></tr>";
      print "</form>";
      $select = "SELECT id,city_name,ats_name,type_name,man_name,name,ip,mac,serial,ports,ports_count,con_name,to_char(inst_date,'DD/MM/YYYY') as inst_date
		 FROM $schema.$table
		 WHERE 1=1";
	if ($s_city_name ne "")
	{
	  $select = $select." AND UPPER(city_name) like UPPER('%$s_city_name%')";
	}
	if ($s_ats_name ne "")
	{
	  $select = $select." AND UPPER(ats_name) like UPPER('%$s_ats_name%')";
	}
	if ($s_type_name ne "")
	{
	  $select = $select." AND UPPER(type_name) like UPPER('%$s_type_name%')";
	}
	if ($s_man_name ne "")
	{
	  $select = $select." AND UPPER(man_name) like UPPER('%$s_man_name%')";
	}
	if ($s_eq_name ne "")
	{
	  $select = $select." AND name like '%$s_eq_name%'";
	}
	if ($s_ip ne "")
	{
	  $select = $select." AND ip like '%$s_ip%'";
	}
	if ($s_serial ne "")
	{
	  $select = $select." AND UPPER(serial) like UPPER('%$s_serial%')";
	}
	if ($s_mac ne "")
	{
	  $select = $select." AND UPPER(mac) like UPPER('%$s_mac%')";
	}
	if ($s_con_name ne "")
	{
	  $select = $select." AND UPPER(con_name) like UPPER('%$s_con_name%')";
	}
  
      $select .= " ORDER BY city_name,ats_name,type_name,man_name";
	if ($page eq ''){$page=1}
	if ($rows eq ''){$rows=20}
      $f_page=($page-1)*$rows+1;
      $l_page=$f_page+$rows-1;
      $sql0=$db->prepare(qq{SELECT s.*
			    FROM (SELECT rownum rw, s.*
				  FROM ($select) s
				  WHERE rownum <= $l_page
				 ) s
			    WHERE s.rw >= $f_page});
      $sql0->execute();
      print "<form method='post' onsubmit='return func(this);'>";
	while(my($rownum,$ats_eq_id,$city_name,$ats_name,$type_name,$man_name,$eq_name,$ip,$mac,$serial,$ports,$ports_count,$con_name,$date) = $sql0->fetchrow_array)
	{
	    my $left_ports_count = $ports-$ports_count;
	    print "<tr><td>$rownum
		       <td>$city_name
		       <td>$ats_name
		       <td>$type_name
		       <td>$man_name
		       <td><a href='ats_eq.pl?ats_eq_id=$ats_eq_id&action=ats_eq_connect'>$eq_name</a>
		       <td><a href='http://$ip' target='blank'>$ip</a>&nbsp
		       <td>$serial&nbsp;
		       <td>$mac&nbsp;
		       <td>$ports&nbsp;
		       <td>$ports_count&nbsp;
                       <td>$left_ports_count
		  ";
	    print "<td>$con_name&nbsp;<td>$date&nbsp;";
	    
	
	    print "<td><input type='radio' name='ats_eq_id' value='$ats_eq_id'></td></tr>"; 
	}
	$select =~ s/(\SELECT).*/$1 count(*)/;
	$select =~ s/(ORDER.*)//s;
	my $sql1 = $db->prepare($select);
	$sql1->execute;
	my ($eq_count) = $sql1->fetchrow_array;
	my $page_numb = $eq_count/$rows;
	$page_numb =~ s/(\d+).*/$1+1/e;

        print "<tr>";
	print "<td colspan=2><b>Total: $eq_count";

	print "<td colspan=10><center>";
	  for (my $i=1 ;$i<=$page_numb ;++$i)
	  {
	    if ($page==$i){ print " $i"}
	    else 
	    {
		print " <a href='ats_eq.pl?page=$i&rows=$rows&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_type_name=$s_type_name&s_man_name=$s_man_name&s_eq_name=$s_eq_name&s_ip=$s_ip&s_serial=$s_serial&s_mac=$s_mac&s_con_name=$s_con_name'>$i</a>";}
	    }
            print "</center>";
	    print "<td colspan=2 align=right><select 
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
	  if ($rows == 20){$sl = "selected"}else{$sl = ""}
        print "<option value='?page=$i&rows=20&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_type_name=$s_type_name&s_man_name=$s_man_name&s_eq_name=$s_eq_name&s_ip=$s_ip&s_serial=$s_serial&s_mac=$s_mac&s_con_name=$s_con_name' $sl>20</option>";
	  if ($rows == 50){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=50&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_type_name=$s_type_name&s_man_name=$s_man_name&s_eq_name=$s_eq_name&s_ip=$s_ip&s_serial=$s_serial&s_mac=$s_mac&s_con_name=$s_con_name' $sl>50</option>";
	  if ($rows == 100){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=100&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_type_name=$s_type_name&s_man_name=$s_man_name&s_eq_name=$s_eq_name&s_ip=$s_ip&s_serial=$s_serial&s_mac=$s_mac&s_con_name=$s_con_name' $sl>100</option>";
	  if ($rows == 100000){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=100000&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_type_name=$s_type_name&s_man_name=$s_man_name&s_eq_name=$s_eq_name&s_ip=$s_ip&s_serial=$s_serial&s_mac=$s_mac&s_con_name=$s_con_name' $sl>All</option>";
        print "</select>";

	if ($privs_list =~ /INSERT|UPDATE|DELETE/)
	{
	print "<tr><td colspan=15>";
	print "<div align='right'>Choose action: <select name='action'>";
	  if ($privs_list =~ /INSERT/)
	  {
	    print "<option value='add'>Add</option>";
	  }      
	  if ($privs_list =~ /UPDATE/)
	  {
	    print "<option value='edit'>Edit</option>";
	  }      
	  if ($privs_list =~ /DELETE/)
	  {
	    print "<option value='delete'>Delete</option>";
	  }      
	  print "</select>";
	print "<input type='submit' value='Select'></div></td></tr>";
	}
      print "</form>";
      print "</table>";
      print "<script type='text/javascript'>
	    function func(obj){
	      var ats_eq_id_length = obj.ats_eq_id.length;
		  if (obj.action.value == 'edit')
		  {
		    if (!ats_eq_id_length)
		    {
		      if (obj.ats_eq_id.checked == true)
		      {
		       return true;
		      }
		    }
		    else
		    {
		      for (var i=0; i<ats_eq_id_length;i++)
		      {
			if (obj.ats_eq_id[i].checked == true)
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
		    if (!ats_eq_id_length)
		    {
		      if (obj.ats_eq_id.checked == true)
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
		      for (var i=0; i<ats_eq_id_length;i++)
		      {
			if (obj.ats_eq_id[i].checked == true)
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
	print "<br>Isuficient privileges";
      }
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "add")
  {
    &add_edit_form($action);
  }
  elsif($action eq "add_db")
  {
      if ($eq_id =~ /^\d+$/ && $ats_id =~ /^\d+$/ && $serial !~ /[\'\\\"]/i && $mac !~ /[\'\\\"]/i && $ip !~ /[\'\\\"]/i && $ports !~ /[\'\\\"]/i && $date !~ /[\'\\\"]/i && $con_id =~ /^\d+$/)
      {
	$query = "INSERT into $schema.$table(name,ats_id,eq_id,con_id,ip,mac,serial,ports,inst_date)
		  VALUES('$eq_name',$ats_id,$eq_id,$con_id,'$ip','$mac','$serial','$ports',to_date('$date','YYYY-MM-DD'))";
	$redirect = "?action=add&type_id=$type_id&eq_id=$eq_id&city_id=$city_id&ats_id=$ats_id&eq_id=$eq_id&con_id=$con_id&ip=$ip&mac=$mac&serial=$serial&ports=$ports&date=$date";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($ats_eq_id =~ /^\d+$|^$/)
      {
      &add_edit_form($action,$ats_eq_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($ats_eq_id =~ /^\d+$/ && $eq_id =~ /^\d+$/ && $ats_id =~ /^\d+$/ && $serial !~ /[\'\\\"]/i && $mac !~ /[\'\\\"]/i && $ip !~ /[\'\\\"]/i && $ports !~ /[\'\\\"]/i && $date !~ /[\'\\\"]/i && $con_id =~ /^\d+$/)
      {
	$query = "UPDATE $schema.$table
		  SET ats_id = $ats_id,
		      eq_id = $eq_id,
		      ip = '$ip',
		      mac = '$mac',
		      serial = '$serial',
		      ports = '$ports',
		      con_id = $con_id,
		      inst_date = to_date ('$date','YYYY-MM-DD')
		  WHERE id='$ats_eq_id'";
	$redirect = "?action=edit&eq_id=$ats_eq_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($ats_eq_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$ats_eq_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "ats_eq_connect")
  {
    if ($ats_eq_id =~ /^\d+$/)
    {
      print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
      print "<tr><td width='30%' valign=top><table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
      my $sql0 = $db->prepare("SELECT city_name, ats_name, type_name, man_name, name, ip, serial, mac, con_name, inst_date, ports, ports_count
			       FROM $schema.$table
			       WHERE id = '$ats_eq_id'");
      $sql0->execute;
      ($city_name, $ats_name, $eq_type_name, $man_name, $eq_name, $ats_eq_ip, $serial, $mac, $con_name, $date, $ports, $ports_count) = $sql0->fetchrow_array;
      print "<tr><td width=50%><b>City:<td>$city_name";
      print "<tr><td><b>ATS:<td>$ats_name";
      print "<tr><td><b>Equipment Type:<td>$eq_type_name";
      print "<tr><td><b>Manufacturer:<td>$man_name";
      print "<tr valign=top><td><b>Equipment:<td>$eq_name";
      print "<tr><td><b>IP Address:<td><a href='http://$ats_eq_ip' target='blank'>$ats_eq_ip</a> &nbsp;";
      print "<tr><td><b>Mac:<td>$mac &nbsp;";
      print "<tr><td><b>Serial:<td>$serial &nbsp;";
      print "<tr><td><b>Connector:<td>$con_name &nbsp;";
      print "<tr><td><b>Date:<td>$date &nbsp;";
      print "<tr><td><b>Ports:<td>$ports &nbsp;";
      print "<tr><td><b>Ports Used:<td>$ports_count &nbsp;";
      print "<tr><td><b>Logs:<td><a href=reports.pl?action=ats_eq_logs&ats_eq_id=$ats_eq_id>logs</a> &nbsp;";
      print "</table>";
    
      print "<td valign=top><table width=100% border='1' cellspacing='1' cellpadding='1'>";
      print "<tr><th>Slot
		 <th>Port
		 <th>School Name
		 <th>IP
		 <th>MAC
		 <th>Phone
		 <th>Graph";
      my $sql1 = $db->prepare("SELECT a.slot, a.port, a.school_name, a.school_id, a.ip, a.phone, s.mac
			       FROM $schema.ats_eq_ports_v a left join $schema.schools_eq_v s
							      ON (a.school_id = s.school_id and s.connected = 1)
			       WHERE a.eq_id = '$ats_eq_id'
			       ORDER BY a.slot,a.port");
      $sql1->execute;
	while (($slot, $port, $school_name, $school_id, $ip, $phone, $mac) = $sql1->fetchrow_array)
	{
	  $g_port = sprintf("%02d", $port);
	  $g_slot = sprintf("%02d", $slot);
	  if ($g_slot eq "00")
	  {
	    $g_slot = "01";
	  }
	  print "<tr><td align=center>$slot
		     <td align=center>$port
		     <td><a href=schools_info.pl?school_id=$school_id>$school_name</a>
		     <td>$ip
		     <td>$mac
		     <td>$phone
		     <td width=300><img src='http://82.194.0.204/mrtg/$ats_eq_ip/$g_slot-$g_port-day.png' width='300'></img></td>";
	}
      print "</table>";
      print "</table>";

    }
    else
    {
	print "Error";
    }
  }

sub add_edit_form
{
  my($action,$ats_eq_id) = @_;
    if ($action eq "edit" && $ats_eq_id ne "")
    {
      my $sql0 = $db->prepare("SELECT city_id,city_name,ats_id,ats_name,eq_id,type_id,type_name,man_id,man_name,name,ip,mac,serial,ports,con_id,con_name,to_char(inst_date,'YYYY-MM-DD') as inst_date
			       FROM $schema.$table
			       WHERE id='$ats_eq_id'");
      $sql0->execute;
      ($city_id,$city_name,$ats_id,$ats_name,$eq_id,$type_id,$type_name,$man_id,$man_name,$eq_name,$ip,$mac,$serial,$ports,$con_id,$con_name,$date) = $sql0->fetchrow_array;        
    }
  if ($ats_eq_id_new ne ""){$ats_eq_id = $ats_eq_id_new}
  print "<form action='ats_eq.pl' method='get' name='form' onsubmit='return checkForm(this);'>";
  print "<table width='50%' border='1' cellspacing='1' cellpadding='1' align='left'>";

######## Select CITY

    if (!$city_id_new && !$city_id)
    {
      my $sql0 = $db->prepare("SELECT c.*
			       FROM (SELECT id
				     FROM $schema.city_v
				     ORDER BY name) c
			       WHERE rownum <= 1");
      $sql0->execute;
      ($city_id) = $sql0->fetchrow_array;
    }

  print "<tr><td>City:";
  print "<td><select name='city_select'
            onchange=\"if (this.options[this.selectedIndex].value == '') 
            this.selectedIndex=0; 
            else window.open(this.options[this.selectedIndex].value,'_top')\">";
  my $sql0 = $db->prepare("SELECT id,name
                           FROM $schema.city_v
			   ORDER BY name");
  $sql0->execute;
    while (my($id,$city) = $sql0->fetchrow_array)
    {
	if ($city_id eq $id){$sl = "selected"}
	else {$sl = ""}
        print "<option value='ats_eq.pl?action=add&city_id=$id&ats_eq_id_new=$ats_eq_id&type_id=$type_id&eq_id=$eq_id&ip=$ip&mac=$mac&serial=$serial&ports=$ports&date=$date&con_id=$con_id' $sl>$city</option>";
    }
  print "</select>";
  
########

######## Select ATS
    if (!$ats_id)
    {
      my $sql0 = $db->prepare("SELECT c.*
			       FROM ( SELECT id
				      FROM $schema.ats_v
				      WHERE city_id = '$city_id'
				      ORDER BY name) c
			       WHERE rownum <= 1");
      $sql0->execute;
      ($ats_id) = $sql0->fetchrow_array;
    }

  print "<tr><td>ATS:";
  print "<td><select 
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
  my $sql0 = $db->prepare("SELECT id,name
                           FROM $schema.ats_v
			   WHERE city_id = '$city_id'
			   ORDER BY name");
  $sql0->execute;
    while (my($id,$ats) = $sql0->fetchrow_array)
    {
	if ($id eq $ats_id) {$sl = "selected"}
	else {$sl = ""}
        print "<option value='?action=$action&city_id=$city_id&ats_id=$id&eq_id=$eq_id&ats_eq_id_new=$ats_eq_id&type_id=$type_id&eq_id=$eq_id&ip=$ip&mac=$mac&serial=$serial&ports=$ports&date=$date&con_id=$con_id' $sl>$ats</option>";
    }
  print "</select>";
  
########

######## Select Equipment type

    if (!$type_id)
    {
      my $sql0 = $db->prepare("SELECT id,name
			       FROM $schema.select_equipments_type_v
			       WHERE rownum <= 1
			       ORDER BY name
			       ");
      $sql0->execute;
      ($type_id) = $sql0->fetchrow_array;
    }
    
  print "<tr><td width='50%'>Equipment Type: ";
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
	  if ($type_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='?action=$action&city_id=$city_id&ats_id=$ats_id&type_id=$id&ats_eq_id_new=$ats_eq_id&ip=$ip&mac=$mac&serial=$serial&ports=$ports&date=$date&con_id=$con_id' $sl>$type</option>";
      }
  print "</select>";

########

######## Select Equipment

      if ($eq_id eq "")
      {
      my $sql0 = $db->prepare("SELECT description, id
			       FROM $schema.select_eq_man_v
			       WHERE type_id = '$type_id'
			       AND ROWNUM<=1
                               ORDER BY man_name");
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
			   WHERE type_id = '$type_id'
			   ORDER BY man_name");
  $sql0->execute;
      while (my($id,$eq,$man_name,$eq_desc) = $sql0->fetchrow_array)
     { 
	  if ($eq_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='?action=$action&type_id=$type_id&eq_id=$id&eq_desc=$eq_desc&city_id=$city_id&ats_id=$ats_id&ats_eq_id_new=$ats_eq_id&ip=$ip&mac=$mac&serial=$serial&ports=$ports&date=$date&con_id=$con_id' $sl>$man_name $eq</option>";
      }
  print "</select>";

  print "<tr valign=top><td>Description<td>$eq_desc";
  print "<tr><td>IP Address:</td><td><input type='text' name='ip' value='$ip'>";
  print "<tr><td>Mac Address:</td><td><input type='text' name='mac' value='$mac'>";
  print "<tr><td>Equipment Serial:</td><td><input type='text' name='serial' value='$serial'>";
  print "<tr><td>Ports:</td><td><input type='text' name='ports' value='$ports'>";
  print "<tr><td>Date: <td><input type='text' name='date' value='$date'>";
  print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.form.date);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
  print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
  print "<tr><td>Connector:<td><select name='con_id'>";

  my $sql0 = $db->prepare("SELECT id,name
                           FROM $schema.connectors_v
			   ORDER by name");
  $sql0->execute;
    while (my($id,$name) = $sql0->fetchrow_array)
    {
	if ($con_id eq $id){$sl = "selected"}
	else {$sl = ""}
	print "<option value='$id' $sl>$name</option>";
    }
  print "</select>";


  print "<tr><td>&nbsp;</td><td><input type='submit'>";
  print "<input type='hidden' name='city_id' value='$city_id'>";
  print "<input type='hidden' name='ats_id' value='$ats_id'>";
  print "<input type='hidden' name='ats_eq_id' value='$ats_eq_id'>";
  print "<input type='hidden' name='type_id' value='$type_id'>";
  print "<input type='hidden' name='eq_id' value='$eq_id'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "</table>";
  print "</form>";
 
  print "<script>
  	  function checkForm(obj){
		var reg_ip = /\^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\$/i;
		var reg_exp = /[()\%\'\*]/;
		    if (obj.city_select.selectedIndex < 0)
		    {
			alert ('Please select City.');
			return false;
		    }
		    if (obj.type_id.value == '')
		    {
			alert ('Please select equipment type.');
			return false;
		    }

		    if (obj.eq_name.value == '')
		    {
			alert ('Please enter equipment name.');
			return false;
		    }
		    else
		    {
		      if (reg_exp.exec(obj.eq_name.value) != null)
		      {
			alert ('Please enter right equipment name.');
			return false;
		      }
		    }
		    if (obj.ip.value == '')
		    {
			alert ('Please enter IP address.');
			return false;
		    }
		    else
		    {
			if (reg_ip.exec(obj.ip.value) == null)
			{
			alert ('Please enter right IP.');
			return false;
			}
		    }

                }
         </script>";
}

sub add_edit_del_db
{
  my ($query,$redirect) = @_;
  print "$query";
  $sql0=$db->prepare($query);
    if ($sql0->execute)
    {
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='?';
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
  $dbsid="ironleg";
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
