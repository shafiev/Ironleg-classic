#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use utf8;

my $action=param('action');
my $eq_type_id=param('eq_type_id');
my $eq_type_name=param('eq_type_name');



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
$table="equipments_type_v";
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
	       <th>ATS Equipment Count</th>
	       <th>Schools Equipment Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,ats_eq_count,school_eq_count
				FROM $schema.$table) c});
    $sql0->execute();
      while(my($rownum,$eq_type_id,$eq_type_name,$ats_eq_count,$school_eq_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>
		<td>$eq_type_name</td>
		<td><a href='?action=ats_eq_types&eq_type_id=$eq_type_id'>$ats_eq_count</a></td>
		<td><a href='?action=school_eq_types&eq_type_id=$eq_type_id'>$school_eq_count</a></td>
		<td width=10><input type='radio' name='eq_type_id' value='$eq_type_id'></td>
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
	    var eq_type_id_length = obj.eq_type_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!eq_type_id_length)
		  {
		    if (obj.eq_type_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<eq_type_id_length;i++)
		    {
		      if (obj.eq_type_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose equipment type.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!eq_type_id_length)
		  {
		    if (obj.eq_type_id.checked == true)
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
		    for (var i=0; i<eq_type_id_length;i++)
		    {
		      if (obj.eq_type_id[i].checked == true)
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
		  alert('Choose equipment type.')
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
      if ($eq_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "INSERT into $schema.$table(name)
		  VALUES(INITCAP('$eq_type_name'))";
	$redirect = "?action=add&eq_type_name=$eq_type_name";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($eq_type_id =~ /^\d+$/)
      {
      &add_edit_form($action,$eq_type_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($eq_type_id =~ /^\d+$/ && $eq_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "UPDATE $schema.$table
		  SET name = INITCAP('$eq_type_name')
		  WHERE id='$eq_type_id'";
	$redirect = "?action=edit&eq_type_id=$eq_type_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($eq_type_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$eq_type_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "ats_eq_types")
  {
    if ($eq_type_id =~ /^\d+$/)
    {
      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('$schema')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('ats_eq_v')
			    UNION
			    SELECT Privilege
			    FROM role_tab_privs
			    WHERE owner = upper('$schema')
			    AND Table_name = upper('ats_eq_v')});
      $sql0->execute();
      $privs_list="";
      while ($privs = $sql0->fetchrow_array)
      {
	$privs_list = $privs_list."_".$privs;
      }
	if ($privs_list =~ /SELECT/)
	{
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<th>N
		 <th>City
		 <th>ATS Name
		 <th>Equipment Type
		 <th>Equipment";
	  my $sql1 = $db->prepare("SELECT rownum, c.*
				   FROM (SELECT city_name,ats_name,name, man_name, type_name, id
				   FROM $schema.ats_eq_v
				   WHERE type_id = $eq_type_id
				   ORDER BY city_name,ats_name) c");
	  $sql1->execute;
	    while (($rownum,$city_name, $ats_name, $eq_name, $man_name, $type_name, $ats_eq_id) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$rownum
			 <td>$city_name
			 <td>$ats_name
			 <td>$type_name
			 <td><a href='ats_eq.pl?action=ats_eq_connect&ats_eq_id=$ats_eq_id'>$man_name $eq_name</a>";
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
  elsif($action eq "school_eq_types")
  {
    if ($eq_type_id =~ /^\d+$/)
    {
      $sql0=$db->prepare(qq{SELECT Privilege 
			    FROM user_tab_privs
			    WHERE owner = upper('$schema')
			    AND Grantee = upper('$dbuser')
			    AND Table_Name = upper('schools_eq_v')
			    UNION
			    SELECT Privilege
			    FROM role_tab_privs
			    WHERE owner = upper('$schema')
			    AND Table_name = upper('schools_eq_v')});
      $sql0->execute();
      $privs_list="";
      while ($privs = $sql0->fetchrow_array)
      {
	$privs_list = $privs_list."_".$privs;
      }
	if ($privs_list =~ /SELECT/)
	{
	  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
	  print "<th>N
		 <th>City
		 <th>School Name
		 <th>Equipment Type
		 <th>Equipment";
	  my $sql1 = $db->prepare("SELECT rownum, c.*
				   FROM (SELECT city_name,school_name,eq_name, man_name, type_name, school_id
					 FROM $schema.schools_eq_v
					 WHERE type_id = $eq_type_id
					 ORDER BY city_name,school_name) c");
	  $sql1->execute;
	    while (($rownum, $city_name, $school_name, $eq_name, $man_name, $type_name, $school_id) = $sql1->fetchrow_array)
	    {
	      print "<tr><td>$rownum
			 <td>$city_name
			 <td><a href='schools_info.pl?school_id=$school_id'>$school_name</a>
			 <td>$type_name
			 <td>$man_name $eq_name";
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
  my($action,$eq_type_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.$table
			       WHERE id='$eq_type_id'");
      $sql0->execute;
      ($eq_type_name) = $sql0->fetchrow_array;        
    }
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Type:</td><td><input type='text' name='eq_type_name' value='$eq_type_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='eq_type_id' value='$eq_type_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*]/;
		var reg_speed = /\^([0-9]+)\$/i;
		    if (obj.eq_type_name.value == '')
		    {
			alert ('Please enter equipment type.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.eq_type_name.value) != null)
			{
			alert ('Please enter right equipment type.');
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
	$error = "Equipment type already exist.";
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
