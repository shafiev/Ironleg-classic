#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $cl_type_id=param('cl_type_id');
my $cl_type_name=param('cl_type_name');



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
$table="clients_type_v";
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
	       <th>Client Type</th>
	       <th>Connect Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,type_count
				FROM $schema.$table
				ORDER BY name) c});
    $sql0->execute();
      while(my($rownum,$cl_type_id,$cl_type_name,$type_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>
		<td>$cl_type_name</td>
		<td><a href='schools.pl?s_type_name=$cl_type_name'>$type_count</a>&nbsp;</td>
		<td width=10><input type='radio' name='cl_type_id' value='$cl_type_id'></td>
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
	    var cl_type_id_length = obj.cl_type_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!cl_type_id_length)
		  {
		    if (obj.cl_type_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<cl_type_id_length;i++)
		    {
		      if (obj.cl_type_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose client type.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!cl_type_id_length)
		  {
		    if (obj.cl_type_id.checked == true)
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
		    for (var i=0; i<cl_type_id_length;i++)
		    {
		      if (obj.cl_type_id[i].checked == true)
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
		  alert('Choose client type.')
		  return false;
		}
		}		
	    </script>";
    }
    else
    {
      print "<br>Insuficient privileges";
    }
  }
  elsif ($action eq "add")
  {
    &add_edit_form($action);
  }
  elsif($action eq "add_db")
  {
      if ($cl_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "INSERT into $schema.$table(name)
		  VALUES(INITCAP('$cl_type_name'))";
	$redirect = "clients_type.pl?action=add&cl_type_name=$cl_type_name";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($cl_type_id =~ /^\d+$/)
      {
      &add_edit_form($action,$cl_type_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($cl_type_id =~ /^\d+$/ && $cl_type_name !~ /[()\%\'\*\\]/i)
      {
	$query = "UPDATE $schema.$table
		  SET name = INITCAP('$cl_type_name')
		  WHERE id='$cl_type_id'";
	$redirect = "?action=edit&cl_type_id=$cl_type_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($cl_type_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$cl_type_id'";
      $redirect = "clients_type.pl";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }

sub add_edit_form
{
  my($action,$cl_type_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.$table
			       WHERE id='$cl_type_id'");
      $sql0->execute;
      ($cl_type_name) = $sql0->fetchrow_array;        
    }
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Client Type:</td><td><input type='text' name='cl_type_name' value='$cl_type_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='cl_type_id' value='$cl_type_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*]/;
		var reg_speed = /\^([0-9]+)\$/i;
		    if (obj.cl_type_name.value == '')
		    {
			alert ('Please enter client type.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.cl_type_name.value) != null)
			{
			alert ('Please enter right client type.');
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
		document.location.href='clients_type.pl';
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
	$error = "Client type already exist.";
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
