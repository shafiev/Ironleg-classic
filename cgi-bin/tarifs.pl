#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $action2=param('action2');
my $tarif_id=param('tarif_id');
my $tarif_h_id=param('tarif_h_id');
my $tarif_name=param('tarif_name');
my $download=param('download');
my $upload=param('upload');
my $limited=param('limited');
my $price=param('price');
my $tarif_date=param('tarif_date');

my $global_tarif_id = $tarif_id;
my $private_users='Home User Adsl';


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
$table="tarifs_v";
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
    

  if ($action eq "")
  {
    if ($privs_list =~ /SELECT/)
    {
    print "<form method='post' onsubmit='return func(this);'>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><th width=1%>N</th>
	       <th>Tarif</th>
	       <th>Download Speed</th>
	       <th>Upload Speed</th>
	       <th>Tarif Date</th>
	       <th>Price</th>
	       <th>Connect Count</th>
	       <th>&nbsp;
	   </tr>";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM (SELECT id,name,download,upload,to_char(tarif_date,'yyyy-mm-dd'),price,limited,tarif_count
				FROM $schema.$table
				ORDER BY name) c});
    $sql0->execute();
      while(my($rownum,$tarif_id,$tarif_name,$download,$upload,$tarif_date,$price,$limited,$tarif_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>";
	    print "<td><a href='tarifs.pl?action=who_are_on_tariff&tarif_id=$tarif_id'>$tarif_name</a></td>";
	    print "	<td>$download &nbsp;</td>
		<td>$upload &nbsp;</td>
		<td>$tarif_date &nbsp;</td>
		<td>$price &nbsp;</td>
		<td>$tarif_count &nbsp;</td>
		<td width=10><input type='radio' name='tarif_id' value='$tarif_id'></td>
	       </tr>";
      }
      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=10>";
      print "<div align='right'>Choose action: <select name='action'>";
        if ($privs_list =~ /INSERT/)
	{
	  print "<option value='add'>Add</option>";
	  print "<option value='tarif_history'>History</option>";
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
	    var tarif_id_length = obj.tarif_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!tarif_id_length)
		  {
		    if (obj.tarif_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<tarif_id_length;i++)
		    {
		      if (obj.tarif_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose tarif.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!tarif_id_length)
		  {
		    if (obj.tarif_id.checked == true)
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
		    for (var i=0; i<tarif_id_length;i++)
		    {
		      if (obj.tarif_id[i].checked == true)
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
		  alert('Choose tarif.')
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
      if ($tarif_name !~ /[()\%\'\*\\]/i && $download =~ /^\d+$/ && $upload =~ /^\d+$/)
      {
	$query = "INSERT into $schema.$table(name,download,upload,limited,tarif_date,price)
		  VALUES('$tarif_name','$download','$upload','$limited',to_date('$tarif_date','yyyy-mm-dd'),'$price')";
	$redirect = "tarifs.pl?action=add&tarif_name=$tarif_name&download=$download&upload=$upload&limited=$limited&tarif_date=$tarif_date&price=$price";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($tarif_id =~ /^\d+$/)
      {
      &add_edit_form($action,$tarif_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($tarif_id =~ /^\d+$/ && $tarif_name !~ /[()\%\'\*\\]/i && $download =~ /^\d+$|/ && $upload =~ /^\d+$|/)
      {
	$query = "UPDATE $schema.$table
		  SET name = '$tarif_name',
		      download = '$download',
		      upload = '$upload',
		      limited = '$limited',
		      tarif_date = to_date('$tarif_date','yyyy-mm-dd'),
		      price = '$price'
		  WHERE id='$tarif_id'";
	$redirect = "connectors.pl?action=edit&tarif_id=$tarif_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($tarif_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$tarif_id'";
      $redirect = "tarifs.pl";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "tarif_history")
  {
    if ($tarif_id =~ /^\d+$/)
    {
      print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
      print "<tr><td width='30%' valign=top><table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
      my $sql0 = $db->prepare("SELECT name, download, upload, limited, tarif_count
			       FROM $schema.$table
			       WHERE id = '$tarif_id'");
      $sql0->execute;
      ($tarif_name, $download, $upload, $limited, $tarif_count) = $sql0->fetchrow_array;
      print "<tr><td width=50%><b>Tarif Name:<td>$tarif_name";
      print "<tr><td><b>Download:<td>$download";
      print "<tr><td><b>Upload:<td>$upload";
	if ($limited eq '1') {$ch="checked"} else {$ch=""}
      print "<tr><td><b>Limited:<td><input type=checkbox disabled $ch>";
      print "<tr><td><b>Tarif Count:<td>$tarif_count";
      print "</table>";
    
      print "<td valign=top>";
	if ($action2 eq "")
	{
	  print "<table width=100% border='1' cellspacing='1' cellpadding='1'>";
	  print "<form method='post' onsubmit='return func(this);'>";
	  print "<tr><th>Tarif Date<th>Price<th>&nbsp;";
	  my $sql1 = $db->prepare("SELECT id,to_char(tarif_date,'yyyy-mm-dd'), price
				   FROM $schema.tarifs_history
				   WHERE tarif_id = '$tarif_id'
				   ORDER BY tarif_date");
	  $sql1->execute;
	    while (($tarif_h_id,$tarif_date,$price) = $sql1->fetchrow_array)
	    {
	      print "<tr><td align=center>$tarif_date
			 <td align=center>$price
			 <td width=10><input type='radio' name='tarif_h_id' value='$tarif_h_id'></td>";
  
	    }
	    print "<tr><td colspan=10>";
	    print "<div align='right'>Choose action: <select name='action2'>";
	      if ($privs_list =~ /INSERT/)
	      {
		print "<option value='add'>Add</option>";
	      }      
	      if ($privs_list =~ /DELETE/)
	      {
		print "<option value='delete'>Delete</option>";
	      }      
	      print "</select>";
	    print "<input type=hidden name='action' value='tarif_history'>";
	    print "<input type=hidden name='tarif_id' value='$tarif_id'>";
	    print "<input type='submit' value='Select'></div></td></tr>";
	    print "</form>";
	}
	elsif ($action2 eq "add")
	{
	  print "<table width=50% border='1' cellspacing='1' cellpadding='1'>";
	  print "<form method='post' name='add_history' onsubmit='return checkForm(this);'>";
	  print "<tr><td width=50%><b>Tarif Date:</b>";
	  print "<td><input type=text name='tarif_date' value='$tarif_date' size=12>";
	  print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.add_history.tarif_date);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
	  print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
	  print "<tr><td><b>Price:</b>";
	  print "<td><input type=text name='price' value='$price'>";
	  print "<input type=hidden name='tarif_id' value='$tarif_id'>";
	  print "<input type=hidden name='action' value='add_h_db'>";
	  print "<tr><td>&nbsp;<td><input type=submit>";
	  print "</form>";
	  print "<script>
		  function checkForm(obj){
			var reg_exp = /[()\%\'\*\\s]/;
			var reg_speed = /\^([0-9]+)\$/i;
			    if (obj.tarif_date.value == '')
			    {
				alert ('Please enter tarif date.');
				return false;
			    }
			    if (obj.price.value)
			    {
			      if (reg_speed.exec(obj.price.value) == null)
			      {
			      alert ('Please enter right price.');
			      return false;
			      }
			    }
			    else
			    {
				alert ('Please enter tarif price.');
				return false;			      
			    }

		     }
		 </script>";
	}
	elsif ($action2 eq "delete")
	{
	  if ($tarif_h_id =~ /^\d+$/ && $tarif_id =~ /^\d+$/)
	  {
	    $query = "DELETE from $schema.tarifs_history WHERE id='$tarif_h_id'";
	    $redirect = "tarifs.pl?action=tarif_history&tarif_id=$tarif_id";
	    $redirect2 = "tarifs.pl?action=tarif_history&tarif_id=$tarif_id";
	    &add_edit_del_db($query,$redirect,$redirect2);
	  }
	  else
	  {
	    print "Error";
	  }
	}
      print "</table>";
      print "</table>";
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "add_h_db")
  {
      if ($tarif_date =~ /^\d{4}-\d{2}-\d{2}$/i && $price =~ /^\d+$/ && $tarif_id =~ /^\d+$/)
      {
	$query = "INSERT into $schema.tarifs_history(tarif_id,tarif_date,price)
		  VALUES('$tarif_id',to_date('$tarif_date','yyyy-mm-dd'),'$price')";
	$redirect = "tarifs.pl?action=tarif_history&action2=add&tarif_id=$tarif_id&tarif_date=$tarif_date&price=$price";
	$redirect2 = "tarifs.pl?action=tarif_history&tarif_id=$tarif_id";
	&add_edit_del_db($query,$redirect,$redirect2);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "who_are_on_tariff")
  {
      	#my $sql1 = $db->prepare("SELECT tarif_id,tarif_name,school_name,school_id 
	#				FROM IRONLEG.ats_eq_ports_v where tarif_id = :tarif_id");

	my $sql1 = $db->prepare("SELECT tarif_id,tarif_name,school_name,school_id 
	    FROM IRONLEG.ats_eq_ports_v av LEFT JOIN ironleg.schools_v sv ON av.school_id=sv.id 
	    WHERE av.tarif_id=:tarif_id and 
	    sv.type_id=(select id from IRONLEG.clients_type_v cv where cv.name = :private_users )");
        $sql1->bind_param(":tarif_id",$tarif_id);
        $sql1->bind_param(":private_users",$private_users);
	$sql1->execute;
	print "<table width=100% border='1' cellspacing='1' cellpadding='1'>";

	my $i;
       
	print "<tr><td>N</td><td>Home User Adsl</td></tr>";
	while (my ($tarif_id,$tarif_name,$school_name,$school_id) = $sql1->fetchrow_array)
	{
	  
	  $i++;
	  print "<tr><td>$i</td><td>$tarif_name</td>
			 <td><a href='$site_name/cgi-bin/schools_info.pl?school_id=$school_id'>$school_name</a> 
			 </td></tr>";
	}

	#Selecting Not Private users
        my $sql1 = $db->prepare("SELECT tarif_id,tarif_name,school_name,school_id 
	    FROM IRONLEG.ats_eq_ports_v av LEFT JOIN ironleg.schools_v sv ON av.school_id=sv.id 
	    WHERE av.tarif_id=:tarif_id and 
	    sv.type_id NOT IN (select id from IRONLEG.clients_type_v cv where cv.name = :private_users )");
        $sql1->bind_param(":tarif_id",$tarif_id);
        $sql1->bind_param(":private_users",$private_users);
	$sql1->execute;
	print "<table width=100% border='1' cellspacing='1' cellpadding='1'>";

	$i=0;
	print "<tr><td>Another types of users</td></tr>";
	while (my ($tarif_id,$tarif_name,$school_name,$school_id) = $sql1->fetchrow_array)
	{	
      	    $i++;
	  print "<tr><td>$i</td><td>$tarif_name</td>
			 <td><a href='$site_name/cgi-bin/schools_info.pl?school_id=$school_id'>$school_name</a> 
			 </td></tr>";
	}



	print "</table>";
  }

sub add_edit_form
{
  my($action,$con_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name,download,upload, to_char(tarif_date,'yyyy-mm-dd'),price,limited
			       FROM $schema.$table
			       WHERE id='$tarif_id'");
      $sql0->execute;
      ($tarif_name,$download,$upload,$tarif_date,$price,$limited) = $sql0->fetchrow_array;
      $ld="disabled";
    }
  print "<form name='add_tarif' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='30%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>Tarif:</td><td><input type='text' name='tarif_name' value='$tarif_name'>";
  print "<tr><td width='50%'>Download Speed:</td><td><input type='text' name='download' value='$download'>";
  print "<tr><td width='50%'>Upload Speed:</td><td><input type='text' name='upload' value='$upload'>";
    if ($limited eq '1') {$ch="checked";$d=""} else {$ch="",$d="disabled"}
  print "<tr><td width='50%'>Limited:</td><td><input type='checkbox' name='limited' value='1' onclick='checkall(this,add_tarif.tarif_date,add_tarif.price);' $ch $ld>";
    print "<tr><td>Date: <td><input size=13 type='text' name='tarif_date' value='$tarif_date' $d>";
    print "<a href='javascript:void(0)' onclick='gfPop.fPopCalendar(document.add_tarif.tarif_date);return false;' HIDEFOCUS><img name='popcal' align='absbottom' src='../calend/calbtn.gif' width='34' height='22' border='0' alt=''></a>";
    print "<iframe width=174 height=189 name='gToday:normal:agenda.js' id='gToday:normal:agenda.js' src='../calend/ipopeng.html' scrolling='no' frameborder='0' style='visibility:visible; z-index:999; position:absolute; left:-500px; top:0px;'></iframe>";
  print "<tr><td width='50%'>Price:</td><td><input type='text' name='price' value='$price' $d>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
    if ($action eq 'edit'){print "<input type='hidden' name='limited' value='$limited'>";}
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='tarif_id' value='$tarif_id'>";
  print "</table>";
  print "</form>";
  print "<script>
  	  function checkForm(obj){
		var reg_exp = /[()\%\'\*\\s]/;
		var reg_speed = /\^([0-9]+)\$/i;
		    if (obj.tarif_name.value == '')
		    {
			alert ('Please enter tarif name.');
			return false;
		    }
		    else
		    {
			if (reg_exp.exec(obj.tarif_name.value) != null)
			{
			alert ('Please enter right tarif.');
			return false;
			}
		    }
		    if (obj.download.value)
		    {
		      if (reg_speed.exec(obj.download.value) == null)
		      {
		      alert ('Please enter right download speed.');
		      return false;
		      }
		    }
		    if (obj.upload.value)
		    {
		      if (reg_speed.exec(obj.upload.value) == null)
		      {
		      alert ('Please enter right upload speed.');
		      return false;
		      }
		    }
	     }
  	  function checkall(Element,TarifDate,Price){

                    if (Element.checked == false)
                    {
                      TarifDate.disabled = true;
                      Price.disabled = true;
                    }
                    else
                    {
                      TarifDate.disabled = false;
		      Price.disabled = false;
                    }

                }

         </script>";
}

sub add_edit_del_db
{
  my ($query,$redirect,$redirect2) = @_;
  $sql0=$db->prepare($query);
    if ($sql0->execute)
    {
	if ($redirect2)
	{
	print "<SCRIPT LANGUAGE='javascript'>
		 <!--
		  document.location.href='$redirect2';
		 //-->   
	       </SCRIPT>";	  
	}
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='tarifs.pl';
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
