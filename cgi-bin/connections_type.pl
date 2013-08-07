#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $con_type_id=param('con_type_id');
my $con_type_name=param('con_type_name');



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
$table="connections_type_v";
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
	       <th>Connections Type</th>
	       <th>Connect Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,type_count
				FROM $schema.$table
				ORDER BY name) c});
    $sql0->execute();
      while(my($rownum,$con_type_id,$con_type_name,$type_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>
		<td>$con_type_name</td>
		<td><a href='?action=school_types&con_type_id=$con_type_id'>$type_count</td>
		<td width=10><input type='radio' name='con_type_id' value='$con_type_id'></td>
	       </tr>";
      }
      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=10>";
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
	    var con_type_id_length = obj.con_type_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!con_type_id_length)
		  {
		    if (obj.con_type_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<con_type_id_length;i++)
		    {
		      if (obj.con_type_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose connection type.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!con_type_id_length)
		  {
		    if (obj.con_type_id.checked == true)
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
		    for (var i=0; i<con_type_id_length;i++)
		    {
		      if (obj.con_type_id[i].checked == true)
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
		  alert('Choose connection type.')
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
      if ($con_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "INSERT into $schema.$table(name)
		  VALUES(INITCAP('$con_type_name'))";
	$redirect = "?action=add&con_type_name=$con_type_name";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($con_type_id =~ /^\d+$/)
      {
      &add_edit_form($action,$con_type_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($con_type_id =~ /^\d+$/ && $con_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "UPDATE $schema.$table
		  SET name = INITCAP('$con_type_name')
		  WHERE id='$con_type_id'";
	$redirect = "?action=edit&con_type_id=$con_type_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($con_type_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$con_type_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "school_types")
  {
    if ($con_type_id =~ /^\d+$/)
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
		 <th>Type";
	  my $sql1 = $db->prepare("SELECT a.city_name, a.school_name, a.con_type_name, a.school_id, a.ip, a.phone, s.mac
				   FROM $schema.ats_eq_ports_v a left join $schema.schools_eq_v s
								  on (a.school_id = s.school_id and s.connected = 1)
				   WHERE a.con_type_id = $con_type_id
				   ORDER BY a.city_name,a.school_name");
	  $sql1->execute;
	    while (($city_name, $school_name, $con_type_name, $school_id, $ip, $phone, $mac) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$city_name
			 <td><a href=schools_info.pl?school_id=$school_id>$school_name</a>
			 <td>$phone
			 <td>$ip
			 <td>$mac
			 <td>$con_type_name";
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
  my($action,$con_type_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.$table
			       WHERE id='$con_type_id'");
      $sql0->execute;
      ($con_type_name) = $sql0->fetchrow_array;        
    }
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Type:</td><td><input type='text' name='con_type_name' value='$con_type_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='con_type_id' value='$con_type_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*]/;
		var reg_speed = /\^([0-9]+)\$/i;
		    if (obj.con_type_name.value == '')
		    {
			alert ('Please enter connection type.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.con_type_name.value) != null)
			{
			alert ('Please enter right connection type.');
			return false;
			}
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
	$error = "Connection type already exist.";
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
