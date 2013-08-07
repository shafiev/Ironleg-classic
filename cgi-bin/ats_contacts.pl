#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $ats_id=param('ats_id');
my $ats_cont_id=param('ats_cont_id');
my $ats_cont_type_id=param('ats_cont_type_id');
my $ats_cont_type_name=param('ats_cont_type_name');
my $cont_firstname=param('cont_firstname');
my $cont_surname=param('cont_surname');
my $cont_lastname=param('cont_lastname');
my $workphone=param('workphone');
my $cellphone=param('cellphone');
my $homephone=param('homephone');


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
$dbsid="ironleg";
$schema="ironleg";
$table="ats_contacts_v";
$table1="ats_contacts_type_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";
$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass);

$sql0=$db->prepare(qq{SELECT Privilege 
		      FROM user_tab_privs
		      WHERE owner = upper('ironleg')
		      AND Grantee = upper('$dbuser')
		      AND Table_Name = upper('$table')});
$sql0->execute();
$privs_list="";
  while ($privs = $sql0->fetchrow_array)
  {
    $privs_list = $privs_list."_".$privs;
  }
    
print "$privs_list";

  if ($action eq "")
  {
    if ($privs_list =~ /SELECT/)
    {
      print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
      print "<tr><td width=30% valign=top>";
      print "ATS Info:";
      print "<table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
      $sql0=$db->prepare(qq{SELECT name, city_name, ats_latitude, ats_longitude, ats_altitude, address, cross_cable
			    FROM  $schema.ats_v
			    WHERE id=$ats_id});
      $sql0->execute();
      ($ats_name,$city_name,$ats_latitude,$ats_longitude,$ats_altitude,$ats_address,$cross_cable)= $sql0->fetchrow_array;
      print "<tr><td width=50%>City:</td><td>$city_name</td></tr>";
      print "<tr><td width=50%>ATS:</td><td>$ats_name</td></tr>";
      print "<tr><td width=50%>ATS Address:</td><td>&nbsp;$ats_address</td></tr>";
      print "<tr><td width=50%>Cross Cable:</td><td>&nbsp;$cross_cable</td></tr>";
      print "<tr><td width=50%>ATS Latitude:</td><td>$ats_latitude</td></tr>";
      print "<tr><td width=50%>ATS Longitude:</td><td>$ats_longitude</td></tr>";
      print "<tr><td width=50%>ATS Altitude:</td><td>$ats_altitude</td></tr>";
	if ($ats_latitude != 0 && $ats_longitude != 0)
	{
	  print "<tr><td colspan=2><div align='center'>
				    <div id='mapgoogle' style='width: 100%; height: 300px;'></div>
			    </div></td>";
	}
      print "</table></td>";
      print "<td width=50% valign=top>";
      print "Contacts:";
      print "<table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
      print "<tr>
		<th>Type</th>
		<th>First Name</th>
		<th>Surname</th>
		<th>Last Name</th>
		<th>Work Phone</th>
		<th>Cell Phone</th>
		<th>Home Phone</th>
		<th width=1%>&nbsp;</th>
	     </tr>";
      $sql0=$db->prepare(qq{SELECT id,firstname,lastname,surname,type_name,workphone,cellphone,homephone
			    FROM  $schema.$table
			    WHERE ats_id = $ats_id
			    ORDER BY lastname});
      $sql0->execute();
      print "<form method=post  onsubmit='return func_check(this);'>";
	while (($ats_cont_id,$cont_firstname,$cont_lastname,$cont_surname,$ats_cont_type_name,$workphone,$cellphone,$homephone)= $sql0->fetchrow_array)
	{
	  print "<tr>
		  <td>$ats_cont_type_name</td>
		  <td>$cont_firstname &nbsp;</td>
		  <td>$cont_surname &nbsp;</td>
		  <td>$cont_lastname &nbsp;</td>
		  <td>$workphone &nbsp;</td>
		  <td>$cellphone &nbsp;</td>
		  <td>$homephone &nbsp;</td>
		  <td><input type='radio' name='ats_cont_id' value='$ats_cont_id'></td>
		 </tr>";
	}

      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=10";
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
      print "<input type=hidden name='ats_id' value='$ats_id'>";
      print "<input type='submit' value='Select'></div></td></tr>";
      }
      print "</form>";
      print "<table>";

    print "<script type='text/javascript'>
	  function func_check(obj){
	    var ats_cont_id_length = obj.ats_cont_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!ats_cont_id_length)
		  {
		    if (obj.ats_cont_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<ats_cont_id_length;i++)
		    {
		      if (obj.ats_cont_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose contact.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!ats_cont_id_length)
		  {
		    if (obj.ats_cont_id.checked == true)
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
		    for (var i=0; i<ats_cont_id_length;i++)
		    {
		      if (obj.ats_cont_id[i].checked == true)
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
		  alert('Choose contact.')
		  return false;
		}
		}		
	    </script>";
      

      print "Contacts Type:";

      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('ironleg')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('$table1')});
      $sql0->execute();
      $privs_list_cont_type="";
	while ($privs_cont_type = $sql0->fetchrow_array)
	{
	  $privs_list_cont_type = $privs_list_cont_type."_".$privs_cont_type;
	}
	  
      print "$privs_list_cont_type";
      
	if ($privs_list_cont_type =~ /SELECT/)
	{
	print "<table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
	print "<tr><th>Type</th><th>&nbsp;</th></tr>";
	$sql0=$db->prepare(qq{SELECT id,name
			      FROM  $schema.$table1
			      ORDER BY name});
	$sql0->execute();
	print "<form method=post onsubmit='return func(this);'>";
	  while (($ats_cont_type_id,$ats_cont_type_name)= $sql0->fetchrow_array)
	  {
	    print "<tr><td>$ats_cont_type_name</td>
		       <td width=1%><input type='radio' name='ats_cont_type_id' value='$ats_cont_type_id'></td>
		   </tr>";
	  }
	if ($privs_list_cont_type =~ /INSERT|UPDATE|DELETE/)
	{
	print "<tr><td colspan=10";
	print "<div align='right'>Choose action: <select name='action'>";
	  if ($privs_list_cont_type =~ /INSERT/)
	  {
	    print "<option value='add_cont_type'>Add</option>";
	  }      
	  if ($privs_list_cont_type =~ /UPDATE/)
	  {
	    print "<option value='edit_cont_type'>Edit</option>";
	  }      
	  if ($privs_list_cont_type =~ /DELETE/)
	  {
	    print "<option value='delete_cont_type'>Delete</option>";
	  }      
	  print "</select>";
	print "<input type='submit' value='Select'></div></td></tr>";
	print "<input type=hidden name='ats_id' value='$ats_id'>";
	print "</form>";
	}
	print "<table>";
	}
	else
	{
	  print "<br>Isuficient privileges";
	}
    print "<script type='text/javascript'>
  	  function func(obj){
	    var ats_cont_type_id_length = obj.ats_cont_type_id.length;
		if (obj.action.value == 'edit_cont_type')
		{
		  if (!ats_cont_type_id_length)
		  {
		    if (obj.ats_cont_type_id.checked == true)
		    {
		      return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<ats_cont_type_id_length;i++)
		    {
		      if (obj.ats_cont_type_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose contact type');
		  return false;
		}
		if (obj.action.value == 'delete_cont_type')
		{
		  if (!ats_cont_type_id_length)
		  {
		    if (obj.ats_cont_type_id.checked == true)
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
		    for (var i=0; i<ats_cont_type_id_length;i++)
		    {
		      if (obj.ats_cont_type_id[i].checked == true)
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
		  alert('Choose contact type.')
		  return false;
		}
                }		
	    </script>";


      print "</td></tr></table>";


      print "<script src='http://maps.google.com/maps?file=api&amp;v=3.1&amp;key=ABQIAAAAm9GBs0LnKYd_egF6O197pRQ_nWHbqa19EWGxjZIiSnCLv3hmpRQfKkqCMm0gH3Dk-R_b_N3pZ81nmg' type='text/javascript' encoding='utf-8'></script>
		<script type='text/javascript'>
		//<![CDATA[
	  
		function load()
		{
		  if (GBrowserIsCompatible())
		  {
		    var pntx=$ats_longitude;
		    var pnty=$ats_latitude;
		    var center = new GLatLng(pnty, pntx);
		    var marker = new GMarker(new GLatLng($ats_latitude, $ats_longitude));
		    var map = new GMap2(document.getElementById('mapgoogle'));
		    var map_ctrl=new GLargeMapControl();
		    var map_type_ctrl=new GMapTypeControl();
		    var map_scale_ctrl=new GScaleControl();
		      map.addControl(map_ctrl);
		      map.addControl(map_type_ctrl);
		      map.addControl(map_scale_ctrl);
		      map.setCenter(center, 17, G_HYBRID_MAP);
		      map.addOverlay(marker);
		  }
		}
	      //]]>
	      </script>";
    }
    else
    {
      print "<br>Isuficient privileges";
    }
  }
  elsif ($action eq "add_cont_type")
  {
  &add_edit_cont_type_form($action);
  }
  elsif($action eq "add_cont_type_db")
  {
    if ($ats_cont_type_name !~ /[()\%\'\*\\]/i)
    {
      $query = "INSERT into $schema.ats_contacts_type(name)
		VALUES(initcap('$ats_cont_type_name'))";
      $redirect = "ats_contacts.pl?ats_id=$ats_id";
      $redirect_error = "ats_contacts.pl?ats_id=$ats_id&action=add_cont_type&ats_cont_type_name=$ats_cont_type_name";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit_cont_type")
  {
    if ($ats_cont_type_id =~ /^\d+$/)
    {
    &add_edit_cont_type_form($action,$ats_cont_type_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "edit_cont_type_db")
  {
    if ($ats_cont_type_name !~ /[()\%\'\*\\]/i && $ats_cont_type_id =~ /^\d+$/)
    {
      $query = "UPDATE $schema.ats_contacts_type
		SET name = '$ats_cont_type_name'
		WHERE id = $ats_cont_type_id";
      $redirect = "ats_contacts.pl?ats_id=$ats_id";
      $redirect_error = "ats_contacts.pl?ats_id=$ats_id&action=edit_cont_type&ats_cont_type_id=$ats_cont_type_id";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "delete_cont_type")
  {
    if ($ats_cont_type_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.ats_contacts_type WHERE id='$ats_cont_type_id'";
      $redirect	= "ats_contacts.pl?ats_id=$ats_id";
      $redirect_error = $redirect;
      &add_edit_del_db($query,$redirect,$redirect_error);
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
    if ($cont_firstname !~ /[()\%\'\*\s]/i && $cont_surname !~ /[()\%\'\*]/i && $cont_lastname !~ /[()\%\'\*\s]/i && $ats_cont_type_id =~ /^\d+$/ && $workphone !~ /[\%\'\*a-z]/i && $cellphone !~ /[\%\'\*a-z]/i && $homephone !~ /[\%\'\*a-z]/i)
    {
      $query = "INSERT into $schema.$table(ats_id,type_id,firstname,surname,lastname,workphone,cellphone,homephone)
		VALUES($ats_id,$ats_cont_type_id,initcap('$cont_firstname'),initcap('$cont_surname'),initcap('$cont_lastname'),'$workphone','$cellphone','$homephone')";
      $redirect = "ats_contacts.pl?ats_id=$ats_id";
      $redirect_error = "ats_contacts.pl?action=add&ats_cont_type_id=$ats_cont_type_id&cont_firstname=$cont_firstname&cont_surname=$cont_surname&cont_lastname=$cont_lastname&workphone=$workphone&cellphone=$cellphone&homephone=$homephone";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit")
  {
    &add_edit_form($action,$ats_cont_id);
  }
  elsif($action eq "edit_db")
  {
      if ($ats_cont_id =~ /^\d+$/ && $cont_firstname !~ /[()\%\'\*\s]/i && $cont_surname !~ /[()\%\'\*]/i && $cont_lastname !~ /[()\%\'\*\s]/i && $ats_cont_type_id =~ /^\d+$/ && $workphone !~ /[\%\'\*a-z]/i && $cellphone !~ /[\%\'\*a-z]/i && $homephone !~ /[\%\'\*a-z]/i)
      {
	$query = "UPDATE $schema.$table
		  SET firstname = initcap('$cont_firstname'),
		      surname = initcap('$cont_surname'),
		      lastname = initcap('$cont_lastname'),
		      type_id = $ats_cont_type_id,
		      workphone = '$workphone',
		      cellphone = '$cellphone',
		      homephone = '$homephone',
		      ats_id = $ats_id
		  WHERE id = $ats_cont_id";
	$redirect = "ats_contacts.pl?ats_id=$ats_id";
	$redirect_error = "ats_contacts.pl?action=edit&ats_id=$ats_id&ats_cont_type_id=$ats_cont_type_id&cont_firstname=$cont_firstname&cont_surname=$cont_surname&cont_lastname=$cont_lastname&workphone=$workphone&cellphone=$cellphone&homephone=$homephone";
	&add_edit_del_db($query,$redirect,$redirect_error);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($ats_cont_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE ats_contact_id='$ats_cont_id'";
      $redirect = "ats_contacts.pl?ats_id=$ats_id";
      $redirect_error = "ats_contacts.pl?ats_id=$ats_id";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }

sub add_edit_cont_type_form
{
  my($action,$ats_cont_type_id) = @_;
    if ($action eq "edit_cont_type")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.ats_contacts_type_v
			       WHERE id='$ats_cont_type_id'");
      $sql0->execute;
      ($ats_cont_type_name) = $sql0->fetchrow_array;  
    }
  print "<form action='ats_contacts.pl' method='get' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Contact Type:</td><td><input type='text' name='ats_cont_type_name' value='$ats_cont_type_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='ats_id' value='$ats_id'>";  
  print "<input type='hidden' name='ats_cont_type_id' value='$ats_cont_type_id'>";  
  print "</table>";
  print "</form>";
 
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*]/;
		    if (obj.ats_cont_type_name.value == '')
		    {
			alert ('Please enter contact type.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.ats_cont_type_name.value) != null)
			{
			alert ('Please enter right contact type.');
			return false;
			}
		    }
                }
         </script>";
}

sub add_edit_form
{
  my($action,$ats_cont_id) =@_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT firstname,surname,lastname,type_id,workphone,cellphone,homephone
			       FROM $schema.$table
			       WHERE id='$ats_cont_id'");
      $sql0->execute;
      ($cont_firstname,$cont_surname,$cont_lastname,$ats_cont_type_id,$workphone,$cellphone,$homephone) = $sql0->fetchrow_array;
    }
      print "<form method='post' onsubmit='return checkForm(this);'>";
      print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
      print "<tr><td>Type:<td><select name='ats_cont_type_id'>";
      my $sql0 = $db->prepare("SELECT id,name
			       FROM $schema.ats_contacts_type_v
			       ORDER BY name");
      $sql0->execute;
	while (my($id,$name) = $sql0->fetchrow_array)
	{
	    if ($ats_cont_type_id eq $id) {$sl="selected"}
	    else {$sl=""}
	    print "<option value='$id' $sl>$name</option>";
	}
      print "</select>";
      print "<tr><td width='50%'>First Name:</td><td><input type='text' name='cont_firstname' value='$cont_firstname'>";
      print "<tr><td width='50%'>Surname:</td><td><input type='text' name='cont_surname' value='$cont_surname'>";
      print "<tr><td width='50%'>Last Name:</td><td><input type='text' name='cont_lastname' value='$cont_lastname'>";
      print "<tr><td width='50%'>Work Phone:</td><td><input type='text' name='workphone' value='$workphone'>";
      print "<tr><td width='50%'>Cell Phone:</td><td><input type='text' name='cellphone' value='$cellphone'>";
      print "<tr><td width='50%'>Home Phone:</td><td><input type='text' name='homephone' value='$homephone'>";
      $action .= "_db";
      print "<input type='hidden' name='action' value='$action'>";
      print "<input type='hidden' name='ats_id' value='$ats_id'>";
      print "<input type='hidden' name='ats_cont_id' value='$ats_cont_id'>";
      print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
      print "</table>";
      print "</form>";
     
      print "<script>
	      function checkForm(obj){
		    var reg_exp = /[()\%\'\*\\s]/;
		    var reg_exp_phone = /[\%\'\*a-z]/;
			if (obj.cont_firstname.value == '')
			{
			    alert ('Please enter contact First Name.');
			    return false;
			}
			else
			{
			    if (reg_exp.exec(obj.cont_firstname.value) != null)
			    {
			    alert ('Please enter right contact First Name.');
			    return false;
			    }
			}
			
			if (reg_exp.exec(obj.cont_surname.value) != null)
			{
			alert ('Please enter right contact Surname.');
			return false;
			}
			if (reg_exp.exec(obj.cont_lastname.value) != null)
			{
			alert ('Please enter right contact Last Name.');
			return false;
			}
    
			if (reg_exp_phone.exec(obj.workphone.value) != null)
			{
			alert ('Please enter right work phone.');
			return false;
			}
			if (reg_exp_phone.exec(obj.cellphone.value) != null)
			{
			alert ('Please enter right cell phone.');
			return false;
			}
			if (reg_exp_phone.exec(obj.homephone.value) != null)
			{
			alert ('Please enter right home phone.');
			return false;
			}
    
		    }
	     </script>";
}

sub add_edit_del_db
{
  my ($query,$redirect,$redirect_error) = @_;
  print " $query";
  $sql0=$db->prepare($query);
    if ($sql0->execute)
    {
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='$redirect';
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
	$error = "Contact type already exist.";
      }
	print "<SCRIPT LANGUAGE='javascript'>
		<!--
		  alert('$error');
		  document.location.href='$redirect_error';
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
  $ENV{ORACLE_HOME}="/opt/oracle/product/11.2.0/db/";

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
