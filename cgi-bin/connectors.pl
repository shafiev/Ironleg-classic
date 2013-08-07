#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $con_id=param('con_id');
my $con_name=param('con_name');
my $fullname=param('fullname');
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
$dbsid="IRONLEG";
$schema="ironleg";
$table="connectors_v";
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
	       <th>Name</th>
	       <th>Full Name</th>
	       <th>Work Phone</th>
	       <th>Cell Phone</th>
	       <th>Home Phone</th>
	       <th>ATS Equipment Count</th>
	       <th>Schools Count</th>
	       <th>Schools Equipment Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,fullname,workphone,cellphone,homephone,schools_count,eq_count,ats_count
				FROM $schema.$table
				ORDER BY name) c});
    $sql0->execute();
      while(my($rownum,$con_id,$con_name,$fullname,$workphone,$cellphone,$homephone,$schools_count,$eq_count,$ats_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>
		<td>$con_name</td>
		<td>$fullname &nbsp;</td>
		<td>$workphone &nbsp;</td>
		<td>$cellphone &nbsp;</td>
		<td>$homephone &nbsp;</td>
		<td>$ats_count</td>
		<td><a href='connectors.pl?action=connected_schools&con_id=$con_id'>$schools_count</a></td>
		<td><a href='connectors.pl?action=connected_eq&con_id=$con_id'>$eq_count</a></td>
		<td width=10><input type='radio' name='con_id' value='$con_id'></td>
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
	    var con_id_length = obj.con_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!con_id_length)
		  {
		    if (obj.con_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<con_id_length;i++)
		    {
		      if (obj.con_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose connector.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!con_id_length)
		  {
		    if (obj.con_id.checked == true)
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
		    for (var i=0; i<con_id_length;i++)
		    {
		      if (obj.con_id[i].checked == true)
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
		  alert('Choose connector.')
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
      if ($con_name !~ /[()\%\'\*\\]/i && $fullname !~ /[()\%\'\*\\]/i && $workphone !~ /[\%\'\*a-z]/i && $cellphone !~ /[\%\'\*a-z]/i && $homephone !~ /[\%\'\*a-z]/i)
      {
	$query = "INSERT into $schema.$table(name,fullname,workphone,cellphone,homephone)
		  VALUES(INITCAP('$con_name'),INITCAP('$fullname'),'$workphone','$cellphone','$homephone')";
	$redirect = "connectors.pl?action=add&con_name=$con_name&fullname=$fullname&workphone=$workphone&cellphone=$cellphone&homephone=$homephone";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($con_id =~ /^\d+$/)
      {
      &add_edit_form($action,$con_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($con_id =~ /^\d+$/ && $con_name !~ /[()\%\'\*\\]/i && $fullname !~ /[()\%\'\*\\]/i && $workphone !~ /[\%\'\*a-z]/i && $cellphone !~ /[\%\'\*a-z]/i && $homephone !~ /[\%\'\*a-z]/i)
      {
	$query = "UPDATE $schema.$table
		  SET name = initcap('$con_name'),
		      fullname = initcap('$fullname'),
		      workphone = '$workphone',
		      cellphone = '$cellphone',
		      homephone = '$homephone'
		  WHERE id='$con_id'";
	$redirect = "connectors.pl?action=edit&con_id=$con_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($con_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$con_id'";
      $redirect = "connectors.pl";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "connected_schools")
  {
    if ($con_id =~ /^\d+$/)
    {
      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('$schema')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('connectors_schools_v')
			    UNION
			    SELECT Privilege
			    FROM role_tab_privs
			    WHERE owner = upper('$schema')
			    AND Table_name = upper('connectors_schools_v')});
      $sql0->execute();
      $privs_list="";
      while ($privs = $sql0->fetchrow_array)
      {
	$privs_list = $privs_list."_".$privs;
      }
	if ($privs_list =~ /SELECT/)
	{
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<tr><td width='30%' valign=top><table width=100% border='1' cellspacing='1' cellpadding='1'>";
	  my $sql0 = $db->prepare("SELECT name,fullname,workphone,cellphone,homephone
				   FROM $schema.connectors_v
				   WHERE id = '$con_id'");
	  $sql0->execute;
	  ($con_name,$con_fullname,$workphone,$cellphone,$homephone) = $sql0->fetchrow_array;
	  print "<tr><td><b>Name:<td>$con_name";
	  print "<tr><td><b>Full Name:<td>$con_fullname";
	  print "<tr><td><b>Work Phone:<td>$workphone &nbsp;";
	  print "<tr><td><b>Cell Phone:<td>$cellphone &nbsp;";
	  print "<tr><td><b>Home Phone:<td>$homephone &nbsp;";
	  print "</table>";
	  print "<td valign=top><table width=100% border='1' cellspacing='1' cellpadding='1'>";
	  print "<th>City<th>ATS<th>School Name";
	  my $sql1 = $db->prepare("SELECT city_name,ats_name,school_name,school_id
				   FROM $schema.connectors_schools_v
				   WHERE connector_id = $con_id");
	  $sql1->execute;
	    while (($city_name, $ats_name, $school_name, $school_id) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$city_name<td>$ats_name<td><a href=schools_info.pl?school_id=$school_id>$school_name";
	    }
	  print "</table>";
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
  elsif($action eq "connected_eq")
  {
    if ($con_id =~ /^\d+$/)
    {
      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('$schema')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('connectors_eq_v')
			    UNION
			    SELECT Privilege
			    FROM role_tab_privs
			    WHERE owner = upper('$schema')
			    AND Table_name = upper('connectors_eq_v')});
      $sql0->execute();
      $privs_list="";
      while ($privs = $sql0->fetchrow_array)
      {
	$privs_list = $privs_list."_".$privs;
      }
	if ($privs_list =~ /SELECT/)
	{
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<tr><td width='30%' valign=top><table width=100% border='1' cellspacing='1' cellpadding='1'>";
	  my $sql0 = $db->prepare("SELECT name,fullname,workphone,cellphone,homephone
				   FROM $schema.connectors_v
				   WHERE id = '$con_id'");
	  $sql0->execute;
	  ($con_name,$con_fullname,$workphone,$cellphone,$homephone) = $sql0->fetchrow_array;
	  print "<tr><td><b>Name:<td>$con_name";
	  print "<tr><td><b>Full Name:<td>$con_fullname";
	  print "<tr><td><b>Work Phone:<td>$workphone &nbsp;";
	  print "<tr><td><b>Cell Phone:<td>$cellphone &nbsp;";
	  print "<tr><td><b>Home Phone:<td>$homephone &nbsp;";
	  print "</table>";
	  print "<td valign=top><table width=100% border='1' cellspacing='1' cellpadding='1'>";
	  print "<th>City<th>School Name<th>Equipment Type<th>Manufacturer<th>Equipment";
	  my $sql1 = $db->prepare("SELECT city_name,school_name,type_name,man_name,eq_name,school_id
				   FROM $schema.connectors_eq_v
				   WHERE con_id = $con_id");
	  $sql1->execute;
	    while (($city_name, $school_name, $type_name, $man_name, $eq_name, $school_id) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$city_name
			 <td><a href=schools_info.pl?school_id=$school_id>$school_name</a>
			 <td>$type_name
			 <td>$man_name
			 <td>$eq_name";
	    }
	  print "</table>";
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
  my($action,$con_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name,fullname,workphone,cellphone,homephone
			       FROM $schema.$table
			       WHERE id='$con_id'");
      $sql0->execute;
      ($con_name,$fullname,$workphone,$cellphone,$homephone) = $sql0->fetchrow_array;        
    }
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Name:</td><td><input type='text' name='con_name' value='$con_name'>";
  print "<tr><td width='50%'>Full Name:</td><td><input type='text' name='fullname' value='$fullname'>";
  print "<tr><td width='50%'>Work Phone:</td><td><input type='text' name='workphone' value='$workphone'>";
  print "<tr><td width='50%'>Cell Phone:</td><td><input type='text' name='cellphone' value='$cellphone'>";
  print "<tr><td width='50%'>Home Phone:</td><td><input type='text' name='homephone' value='$homephone'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='con_id' value='$con_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*\\s]/;
		var reg_exp_phone = /[\%\'\*a-z]/;
		    if (obj.con_name.value == '')
		    {
			alert ('Please enter connector name.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.con_name.value) != null)
			{
			alert ('Please enter right connector name.');
			return false;
			}
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
  my ($query,$redirect) = @_;
  $sql0=$db->prepare($query);
    if ($sql0->execute)
    {
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='connectors.pl';
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
	$error = "City already exist.";
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
  $ENV{ORACLE_HOME}="/opt/oracle/product/11.2.0/db";
  $ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";


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
