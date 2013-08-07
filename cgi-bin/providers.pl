#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

require 'configurations.pl';

my $action=param('action');
my $prov_id=param('prov_id');
my $prov_name=param('prov_name');
my $city_id=param('city_id');
my $ats_id=param('ats_id');
my $ats_eq_id=param('ats_eq_id');
my $prov_id_new=param('prov_id_new');
my $slot=param('slot');
my $port=param('port');



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

#$db="127.0.0.1";
#$dbsid="azedunet";


print "Hello $REMOTE_USER!";
       
$db="127.0.0.1";
$dbsid="IRONLEG";
$schema="ironleg";
$table="providers_v";
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
    
#print "$privs_list";

  if ($action eq "")
  {
    if ($privs_list =~ /SELECT/)
    {
    print "<form method='post' onsubmit='return func(this);'>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><th width=1%>N</th>
	       <th>Providers</th>
	       <th>City</th>
	       <th>ATS</th>
	       <th>Equipment Type</th>
	       <th>Equipment</th>
	       <th>Slot</th>
	       <th>Port</th>
	       <th width=30>Connect Count</th>
	       <th>Graph</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,city_name,ats_name,eq_name,type_name,man_name,slot,port,providers_count,ats_eq_ip
				FROM $schema.$table
				ORDER BY name) c});
    $sql0->execute();
      while(my($rownum,$prov_id,$prov_name,$city_name,$ats_name,$eq_name,$type_name,$man_name,$slot,$port,$prov_count,$ats_eq_ip) = $sql0->fetchrow_array)
      {
	$g_port = sprintf("%02d", $port);
	$g_slot = sprintf("%02d", $slot);
	print "<tr valign=top>
		<td>$rownum</td>
		<td>$prov_name</td>
		<td>$city_name &nbsp;</td>
		<td>$ats_name &nbsp;</td>
		<td>$type_name &nbsp;</td>
		<td>$man_name $eq_name &nbsp;</td>
		<td>$slot &nbsp;</td>
		<td>$port &nbsp;</td>
		<td align=right><a href='?action=school_providers&prov_id=$prov_id'>$prov_count</a></td>
		<td width=400><img src='http://$path_for_images_of_mrtg/mrtg/$ats_eq_ip/$g_slot-$g_port-day.png' width='400'></img></td>
		<td width=10><input type='radio' name='prov_id' value='$prov_id'></td>
	       </tr>";
      }
      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=11>";
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
	    var prov_id_length = obj.prov_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!prov_id_length)
		  {
		    if (obj.prov_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<prov_id_length;i++)
		    {
		      if (obj.prov_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose provider.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!prov_id_length)
		  {
		    if (obj.prov_id.checked == true)
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
		    for (var i=0; i<prov_id_length;i++)
		    {
		      if (obj.prov_id[i].checked == true)
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
		  alert('Choose provider.')
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
  elsif ($action eq "add")
  {
    &add_edit_form($action);
  }
  elsif($action eq "add_db")
  {
      if ($prov_name !~ /[()\%\'\*\\]/i && $ats_eq_id =~ /^\d+$|^$/ && $slot =~ /^\d+$|^$/ && $port =~ /^\d+$|^$/)
      {
	  if (!$slot || !port) {$ats_eq_id=''}
	$query = "INSERT into $schema.$table(name,ats_eq_id,slot,port)
		  VALUES(INITCAP('$prov_name'),'$ats_eq_id','$slot','$port')";
	$redirect = "?action=add&prov_name=$prov_name";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($prov_id =~ /^\d+$|^$/)
      {
      &add_edit_form($action,$prov_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($prov_id =~ /^\d+$/ && $prov_name !~ /[()\%\'\*\\]/i && $ats_eq_id =~ /^\d+$|^$/ && $slot =~ /^\d+$|^$/ && $port =~ /^\d+$|^$/)
      {
	  if ($slot eq "" || $port eq ""){$ats_eq_id=''}
	$query = "UPDATE $schema.$table
		  SET name = INITCAP('$prov_name'),
		      ats_eq_id = '$ats_eq_id',
		      slot = '$slot',
		      port = '$port'
		  WHERE id='$prov_id'";
	$redirect = "?action=edit&prov_id=$prov_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($prov_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$prov_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "school_providers")
  {
    if ($prov_id =~ /^\d+$/)
    {
      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('$schema')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('ats_eq_ports_v')
			    UNION
			    SELECT Privilege
			    FROM role_tab_privs
			    WHERE owner = upper('$schema')
			    AND Table_name = upper('ats_eq_ports_v')});
      $sql0->execute();
      $privs_list="";
      while ($privs = $sql0->fetchrow_array)
      {
	$privs_list = $privs_list."_".$privs;
      }
	if ($privs_list =~ /SELECT/)
	{
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<th>City
	         <th>School Name
		 <th>Phone
		 <th>IP
		 <th>MAC
		 <th>Provider";
	  my $sql1 = $db->prepare("SELECT a.city_name,a.school_name,a.prov_name,a.school_id,a.ip, a.phone, s.mac
				   FROM $schema.ats_eq_ports_v a LEFT JOIN $schema.schools_eq_v s
								  ON (a.school_id = s.school_id and s.connected = 1)
				   WHERE prov_id = $prov_id
				   ORDER BY city_name,school_name");
	  $sql1->execute;
	    while (($city_name, $school_name, $prov_name, $school_id, $ip, $phone, $mac) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$city_name
			 <td><a href=schools_info.pl?school_id=$school_id>$school_name</a>
			 <td>$phone
			 <td>$ip
			 <td>$mac
			 <td>$prov_name";
	    }
	  print "</table>";
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


sub add_edit_form
{
  my($action,$prov_id) = @_;
    if ($action eq "edit" && $prov_id)
    {
      my $sql0 = $db->prepare("SELECT name,ats_eq_id,slot,port,city_id,ats_id
			       FROM $schema.$table
			       WHERE id='$prov_id'");
      $sql0->execute;
      ($prov_name,$ats_eq_id,$slot,$port,$city_id,$ats_id) = $sql0->fetchrow_array;        
    }
    
	if ($city_id eq '')
	{
	    my $sql2 = $db->prepare("SELECT id
				     FROM $schema.select_city_v
				     WHERE rownum <=1");
	    $sql2->execute;
	    $city_id = $sql2->fetchrow_array;
	}
    if ($prov_id_new ne ""){$prov_id = $prov_id_new}
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
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
	    print "<option value='providers.pl?action=$action&prov_id_new=$prov_id&city_id=$id&slot=$slot&port=$port&prov_name=$prov_name' $sl>$city</option>";
	}
    print "</select>";

	if ($ats_id eq '')
	{
	    my $sql2 = $db->prepare("SELECT id,eq_count
				     FROM $schema.select_ats_v
				     WHERE city_id='$city_id'
				     AND eq_count > 0
				     AND rownum <=1");
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
			     WHERE city_id = $city_id
			     AND eq_count > 0");
    $sql0->execute;
	while (my($id,$ats,$eq_count) = $sql0->fetchrow_array)
	{
		if ($ats_id eq $id){$sl = "selected"}
		else {$sl = ""}
#		if ($eq_count == 0){$prov_type_new = 2}
#		else {$prov_type_new = 0}
	    print "<option value='providers.pl?action=$action&prov_id_new=$prov_id&city_id=$city_id&ats_id=$id&slot=$slot&port=$port&prov_name=$prov_name' $sl>$ats</option>";
	}
    print "</select>";

    print "<tr><td>ATS Equipment:<td><select name='ats_eq_id'>";
    my $sql1 = $db->prepare("SELECT id, man_name, eq_name
			     FROM $schema.select_ats_eq_man_v
			     WHERE ats_id = $ats_id");
    $sql1->execute;
	while (my($id,$man_name,$ats_eq) = $sql1->fetchrow_array)
	{
	    if ($ats_eq_id eq $id){$sl="selected"}
	    else{$sl=""}
	    print "<option value='$id' $sl>$man_name $ats_eq</option>";
	}
    print "</select>";

  print "<tr><td width='50%'>Slot:</td><td><input type='text' name='slot' value='$slot'>";
  print "<tr><td width='50%'>Port:</td><td><input type='text' name='port' value='$port'>";

  print "<tr><td width='50%'>Provider:</td><td><input type='text' name='prov_name' value='$prov_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='ats_eq_id' value='$ats_eq_id'>";
  print "<input type='hidden' name='prov_id' value='$prov_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*\\s]/;
		var reg_slot = /\^([0-9]+)\$\|\^\$/i;
		    if (obj.prov_name.value == '')
		    {
			alert ('Please enter provider.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.prov_name.value) != null)
			{
			alert ('Please enter right provider.');
			return false;
			}
		    }
		    if (reg_slot.exec(obj.slot.value) == null)
		    {
		    alert ('Please enter right slot.');
		    return false;
		    }
		    if (reg_slot.exec(obj.port.value) == null)
		    {
		    alert ('Please enter right port.');
		    return false;
		    }
		    
	     }
         </script>";
}

sub add_edit_del_db
{
  my ($query,$redirect) = @_;
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
	$error = "Provider already exist.";
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
