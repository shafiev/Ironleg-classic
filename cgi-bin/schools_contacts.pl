#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $school_id=param('school_id');
my $cont_id=param('cont_id');
my $cont_name=param('cont_name');
my $phone=param('phone');
my $cont_type_id=param('cont_type_id');
my $cont_type_name=param('cont_type_name');
my $cont_action=param('cont_action');


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
$table="schools_v";
$contacts_table="school_contacts_v";
$contacts_type_table="school_contacts_type_v";
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

    my $sql0 = $db->prepare("SELECT name,city_name,address,description,type_name
                             FROM $schema.$table
                             WHERE id = '$school_id'");
    $sql0->execute;
    ($school_name,$city_name,$address,$school_desc,$type_name) = $sql0->fetchrow_array;
     
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1'>";     
    print "<tr><td width='20%' valign='top'>School Info: <br>";
    print "<table width='100%'  border='1' cellspacing='1' cellpadding='1' align='left'>";
    print "<tr><td width=50%>City: <td>$city_name";
    print "<tr><td valign=top>Type: <td>$type_name";
    print "<tr><td valign=top>School Name: <td>$school_name";
    print "<tr><td>Address: <td>$address &nbsp";
    print "<tr><td>Description: <td>$school_desc &nbsp;";
    print "</table>";
    print "</td>";
    
  if ($action eq "")
  {

  }
  elsif ($action eq "add_type")
  {
  &add_edit_cont_type_form($action);
  }
  elsif($action eq "add_type_db")
  {
    if ($cont_type_name !~ /[()\%\'\*\\]/i)
    {
      $query = "INSERT into $schema.$contacts_type_table(name)
		VALUES(initcap('$cont_type_name'))";
      $redirect = "schools_contacts.pl?school_id=$school_id&action=$cont_action&cont_id=$cont_id";
      $redirect_error = "schools_contacts.pl?school_id=$ats_id&action=add_type&acont_type_name=$cont_type_name&cont_action=$cont_action";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit_type")
  {
    if ($cont_type_id =~ /^\d+$/)
    {
    &add_edit_cont_type_form($action,$cont_type_id);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "edit_type_db")
  {
    if ($cont_type_name !~ /[()\%\'\*\\]/i && $cont_type_id =~ /^\d+$/)
    {
      $query = "UPDATE $schema.$contacts_type_table
		SET name = initcap ('$cont_type_name')
		WHERE id = $cont_type_id";
      $redirect = "schools_contacts.pl?school_id=$ats_id&action=$cont_action&cont_id=$cont_id";
      $redirect_error = "schools_contacts.pl?school_id=$school_id&action=edit_cont_type&cont_type_id=$cont_type_id";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "delete_type")
  {
    if ($cont_type_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$contacts_type_table WHERE id='$cont_type_id'";
      $redirect	= "schools_contacts.pl?school_id=$school_id&cont_id=$cont_id&action=$cont_action";
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
    &add_edit_form($action,$school_id);
  }
  elsif($action eq "add_db")
  {
    if ($school_id =~ /^\d+$/ && $cont_type_id =~ /^\d+$/ && $cont_name !~ /[\\\/\']/ && $phone !~ /[\\\/\'a-z]/)
    {
      $query = "INSERT into $schema.$contacts_table(name,phone,school_id,type_id)
		VALUES(initcap('$cont_name'),'$phone','$school_id','$cont_type_id')";
      $redirect = "schools_info.pl?school_id=$school_id";
      $redirect_error = "schools_contacts.pl?action=add&school_id=$school_id&cont_type_id=$cont_type_id&cont_name=$cont_name&phone=$phone";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "edit")
  {
    &add_edit_form($action,$school_id,$cont_id);
  }
  elsif($action eq "edit_db")
  {
      if ($cont_id =~ /^\d+$/ && $cont_name !~ /[()\%\'\*]/i && $phone !~ /[\\\/\'a-z]/i && $cont_type_id =~ /^\d+$/ && $school_id =~ /^\d+$/)
      {
	$query = "UPDATE $schema.$contacts_table
		  SET name = initcap('$cont_name'),
		      phone = '$phone',
		      school_id = '$school_id',
		      type_id = '$cont_type_id'
		  WHERE id = $cont_id";
	$redirect = "schools_info.pl?school_id=$school_id";
	$redirect_error = "schools_contacts.pl?action=edit&school_id=$school_id&cont_type_id=$cont_type_id";
	&add_edit_del_db($query,$redirect,$redirect_error);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($cont_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$contacts_table WHERE id='$cont_id'";
      $redirect = "schools_info.pl?school_id=$school_id";
      $redirect_error = "schools_info.pl?school_id=$school_id";
      &add_edit_del_db($query,$redirect,$redirect_error);
    }
    else
    {
      print "Error";
    }
  }

sub add_edit_cont_type_form
{
  my($action,$cont_type_id) = @_;
    if ($action eq "edit_type")
    {
      my $sql0 = $db->prepare("SELECT name
			       FROM $schema.$contacts_type_table
			       WHERE id='$cont_type_id'");
      $sql0->execute;
      ($cont_type_name) = $sql0->fetchrow_array;  
    }
  print "<td valign=top width=50%>Add Contact: <br>";
  print "<form action='schools_contacts.pl' method='get' onsubmit='return checkForm(this);'>";
  print "<table width='50%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Contact Type:</td><td><input type='text' name='cont_type_name' value='$cont_type_name'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  print "<input type='hidden' name='cont_action' value='$cont_action'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='school_id' value='$school_id'>";
  print "<input type='hidden' name='cont_id' value='$cont_id'>";
  print "<input type='hidden' name='cont_type_id' value='$cont_type_id'>";  
  print "</table>";
  print "</form>";
 
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*]/;
		
		    if (obj.cont_type_name.value == '')
		    {
			alert ('Please enter contact type.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.cont_type_name.value) != null)
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
  my($action,$school_id,$cont_id) =@_;
  
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name,phone,type_id
			       FROM $schema.$contacts_table
			       WHERE id='$cont_id'");
      $sql0->execute;
      ($cont_name,$phone,$cont_type_id) = $sql0->fetchrow_array;        
    }
    
  print "<td valign=top width=30%>Add Contact: <br>";
  print "<form method='get' onsubmit='return checkForm(this);'>";
  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td>Contact Name:</td><td><input type='text' name='cont_name' value='$cont_name'>";
  print "<tr><td>Contact Type:<td><select name='cont_type_id'>";
  my $sql0 = $db->prepare("SELECT id,name
                           FROM $schema.$contacts_type_table
			   ORDER BY name");
  $sql0->execute;
    while (my($id,$name) = $sql0->fetchrow_array)
    {
        if ($cont_type_id eq $id) {$sl="selected"}
        else {$sl=""}
        print "<option value='$id' $sl>$name</option>";
    }
  print "</select>";
  print "<tr><td>Phone Number:</td><td><input type='text' name='phone' value='$phone'>";
  print "<tr><td>&nbsp;</td><td><input type='submit'>";
  print "<input type='hidden' name='school_id' value='$school_id'>";
  print "<input type='hidden' name='cont_id' value='$cont_id'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "</table>";
  print "</form>";
 
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[\'\*\=]/;
		var reg_phone = /[a-z\'\*\=]/;
		    if (obj.cont_name.value == '')
		    {
			alert ('Please enter contact name.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.cont_name.value) != null)
			{
			alert ('Please enter right tarif name.');
			return false;
			}
		    }
		    if (obj.phone.value == '')
		    {
			alert ('Please enter phone number.');
			return false;
		    }
		    else
		    {
			if (reg_phone.exec(obj.phone.value) != null)
			{
			alert ('Please enter right phone number.');
			return false;
			}
		    }
                }
         </script>";

  print "<td valign=top width=20%>Contact Types: <br>";
  &show_types($school_id,$cont_id);
}

sub show_types
{
  my($school_id,$cont_id) =@_;
  $sql0=$db->prepare(qq{SELECT Privilege 
			FROM user_tab_privs
			WHERE owner = upper('$schema')
			AND Grantee = upper('$dbuser')
			AND Table_Name = upper('$contacts_type_table')});
  $sql0->execute();
  $privs_list_cont="";
    while ($privs_cont = $sql0->fetchrow_array)
    {
      $privs_list_cont .= "_".$privs_cont;
    }
    if ($privs_list_cont =~ /SELECT/)
    {
      print "<form method='post' onsubmit='return func_check(this);'>";
      print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
      print "<tr><th>Contact Type<th>&nbsp;";
      my $sql1 = $db->prepare("SELECT id,name
			       FROM $schema.$contacts_type_table
			       ORDER BY name");
      $sql1->execute;
	while (my($cont_type_id,$cont_type_name) = $sql1->fetchrow_array)
	{
	print "<tr><td>$cont_type_name<td width='20'><input type='radio' name='cont_type_id' value='$cont_type_id'>"; 
	}
      if ($privs_list_cont =~ /INSERT|UPDATE|DELETE/)
      {
	print "<tr><td colspan=6>";
	print "<div align='right'><select name='action'>";
        if ($privs_list_cont =~ /INSERT/)
	{
	  print "<option value='add_type'>Add</option>";
	}      
        if ($privs_list_cont =~ /UPDATE/)
	{
	  print "<option value='edit_type'>Edit</option>";
	}      
        if ($privs_list_cont =~ /DELETE/)
	{
	  print "<option value='delete_type'>Delete</option>";
	}      

      print "</select>";
      print "<input type='submit'></div></td></tr>";
      }
      print "<input type='hidden' name='school_id' value='$school_id'>";
      print "<input type='hidden' name='cont_id' value='$cont_id'>";
      print "<input type='hidden' name='cont_action' value='$action'>";
    
      print "</form>";
      print "</table>";
    print "<script type='text/javascript'>
  	  function func_check(obj){
	    var cont_type_id_length = obj.cont_type_id.length;
		if (obj.action.value == 'edit_type')
		{
		  if (!cont_type_id_length)
		  {
		    if (obj.cont_type_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<cont_type_id_length;i++)
		    {
		      if (obj.cont_type_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose contact type.');
		  return false;
		}
		if (obj.action.value == 'delete_type')
		{
		  if (!cont_type_id_length)
		  {
		    if (obj.cont_type_id.checked == true)
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
		    for (var i=0; i<cont_type_id_length;i++)
		    {
		      if (obj.cont_type_id[i].checked == true)
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

    }
    else
    {
      print "Insuficient privileges";
    }
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
	$error = "Contact already exist.";
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
