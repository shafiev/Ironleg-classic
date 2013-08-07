#!/usr/bin/perl

use DBI;
use DBD::Oracle;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use utf8;
use Encode;

my $action=param('action');
my $man_id=param('man_id');
#my $man_name=decode utf8=>param('man_name');
my $man_name=param('man_name');



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
$table="manufacturers_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";
#      $ENV{'NLS_NCHAR'}="AL32UTF8";
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
    if ($privs_list =~ /SELECT/)
    {

    print "<form method='post' onsubmit='return func(this);'>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><th width=1%>N</th>
	       <th>Manufacturers</th>
	       <th>ATS Count</th>
	       <th>Schools Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,ats_count,schools_count
				FROM $schema.$table) c});
    $sql0->execute();
      while(my($rownum,$man_id,$man_name,$ats_count,$schools_count) = $sql0->fetchrow_array)
      {
	$e = encode utf8 => $man_name;
	print "<tr>
		<td>$rownum</td>
		<td>$man_name</td>
		<td><a href='ats_eq.pl?s_man_name=$man_name'>$ats_count</a></td>
		<td>$schools_count</td>
		<td width=10><input type='radio' name='man_id' value='$man_id'></td>
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
	    var man_id_length = obj.man_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!man_id_length)
		  {
		    if (obj.man_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<man_id_length;i++)
		    {
		      if (obj.man_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose manufacturer.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!man_id_length)
		  {
		    if (obj.man_id.checked == true)
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
		    for (var i=0; i<man_id_length;i++)
		    {
		      if (obj.man_id[i].checked == true)
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
		  alert('Choose manufacturer.')
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
      if ($man_name !~ /[()\%\'\*\\]/i)
      {
	$query = "INSERT into $schema.$table(name)
		  VALUES('$man_name')";
	$redirect = "?action=add&man_name=$man_name";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($man_id =~ /^\d+$/)
      {
      &add_edit_form($action,$man_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($man_id =~ /^\d+$/ && $man_name !~ /[()\%\'\*\\]/i)
      {
	$query = "UPDATE $schema.$table
		  SET name = '$man_name'
		  WHERE id='$man_id'";
	$redirect = "?action=edit&man_id=$man_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($man_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$man_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }

sub add_edit_form
{
  my($action,$man_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.$table
			       WHERE id='$man_id'");
      $sql0->execute;
      ($man_name) = $sql0->fetchrow_array;        
    }
  print "<form name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Manufacturer:</td><td><input type='text' name='man_name' value='$man_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='man_id' value='$man_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*\]/;
		var reg_speed = /\^([0-9]+)\$/i;
		    if (obj.man_name.value == '')
		    {
			alert ('Please enter manufacturer.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.man_name.value) != null)
			{
			alert ('Please enter right manufacturer.');
			return false;
			}
		    }
	     }
         </script>";
}

sub add_edit_del_db
{
  my ($query,$redirect) = @_;
  print "$ENV{'NLS_LANG'} $query";
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
