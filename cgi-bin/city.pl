#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $city_id=param('city_id');
my $city_name=param('city_name');
my $phone_code=param('phone_code');
my $latitude=param('latitude');
my $longitude=param('longitude');
my $altitude=param('altitude');


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
$table="city_v";
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
    print "<form action='city.pl' method='post' onsubmit='return func(this);'>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><th width=1%>N</th>
	       <th>City</th>
	       <th>Phone code</th>
	       <th>Latitude</th>
	       <th>Longitude</th>
	       <th>Altitude</th>
	       <th>ATS Count</th>
	       <th width=100>Connected ATS count</th>
	       <th>Schools Count</th>
	       <th width=100>Connected Schools count</th>
	       <th>&nbsp;
	   </tr>";
    $select = "SELECT id,name,phone_code,latitude,longitude,altitude,ats_count,schools_count,ats_con_count,schools_con_count
	       FROM $schema.$table
	       ORDER BY name";
    $sql0=$db->prepare(qq{SELECT rownum, c.*
			  FROM ($select) c});
    $sql0->execute();
      while(my($rownum,$city_id,$city_name,$phone_code,$latitude,$longitude,$altitude,$ats_count,$schools_count,$ats_con_count,$schools_con_count) = $sql0->fetchrow_array)
      {
	print "<tr>
		<td>$rownum</td>
		<td>$city_name</td>
		<td>$phone_code &nbsp;</td>
		<td>$latitude &nbsp;</td>
		<td>$longitude &nbsp;</td>
		<td>$altitude &nbsp;</td>
		<td><a href='ats.pl?s_city_name=$city_name'>$ats_count</a></td>
		<td><a href='ats_eq.pl?s_city_name=$city_name'>$ats_con_count</a></td>
		<td><a href='schools.pl?s_city_name=$city_name'>$schools_count</a></td>
		<td>$schools_con_count</td>
		<td width=10><input type='radio' name='city_id' value='$city_id'></td>
	       </tr>";
      }
      $select =~ s/(\SELECT).*/$1 count(*),sum(ats_count),sum(schools_count),sum(ats_con_count),sum(schools_con_count)/;
      $select =~ s/(ORDER.*)//s;
      $sql1=$db->prepare($select);
      $sql1->execute();
      ($count, $sum_ac, $sum_sc, $sum_acc, $sum_scc) = $sql1->fetchrow_array;
      print "<tr><td><b> Total :<td colspan=5><b>$count<td><b>$sum_ac<td><b>$sum_acc<td><b>$sum_sc<td><b>$sum_scc<td>&nbsp;";
      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=13>";
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
		if (obj.action.value == 'edit')
		{
		  for (var i=0; i<obj.city_id.length;i++)
		  {
		    if (obj.city_id[i].checked == true)
		    {
		     return true;
		    }
		  }
		  alert('Choose City');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  for (var i=0; i<obj.city_id.length;i++)
		  {
		    if (obj.city_id[i].checked == true)
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
		  alert('Choose City')
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
      if ($city_name =~ /^[a-z]+$/i && $phone_code =~ /^\d+$|/ && $latitude =~ /^\d+\.\d+$|0/ && $longitude =~ /^\d+\.\d+$|0/ && $altitude =~ /^\d+$|0|^-\d+$/)
      {
	$query = "INSERT into $schema.$table(name,phone_code,latitude,longitude,altitude)
		  VALUES(INITCAP('$city_name'),'$phone_code',$latitude,$longitude,$altitude)";
	$redirect = "city.pl?action=add&city_name=$city_name&phone_code=$phone_code&latitude=$latitude&longitude=$longitude&altitude=$altitude";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($city_id =~ /^\d+$/)
      {
      &add_edit_form($action,$city_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($city_name =~ /^[a-z]+$/i && $city_id =~ /^\d+$/ && $phone_code =~ /^\d+$|/ && $latitude =~ /^\d+\.\d+$|0/ && $longitude =~ /^\d+\.\d+$|0/ && $altitude =~ /^\d+$|0|^-\d+$/)
      {
	$query = "UPDATE $schema.$table
		  SET name = initcap('$city_name'),
		      phone_code = '$phone_code',
		      latitude = $latitude,
		      longitude = $longitude,
		      altitude = $altitude
		  WHERE id='$city_id'";
	$redirect = "city.pl?action=edit&city_id=$city_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($city_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$city_id'";
      $redirect = "city.pl";
      &add_edit_del_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }

sub add_edit_form
{
  my($action,$city_id) = @_;
    if ($action eq "edit")
    {
      my $sql0 = $db->prepare("SELECT name,phone_code,latitude,longitude,altitude
			       FROM $schema.$table
			       WHERE id='$city_id'");
      $sql0->execute;
      ($city_name,$phone_code,$latitude,$longitude,$altitude) = $sql0->fetchrow_array;        
    }
  print "<form action='city.pl' name='add_city' method='post' onsubmit='return checkForm(this);'>";
  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width=30% valign=top><table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width='50%'>City:</td><td><input type='text' name='city_name' value='$city_name'>";
  print "<tr><td width='50%'>Phone code:</td><td><input type='text' name='phone_code' value='$phone_code'>";
    if (!$latitude){$latitude=0}
    if (!$longitude){$longitude=0} 
    if (!$altitude){$altitude=0}
  print "<tr><td width='50%'>Latitude:</td><td><input type='text' name='latitude' value='$latitude'>";
  print "<tr><td width='50%'>Longitude:</td><td><input type='text' name='longitude' value='$longitude'>";
  print "<tr><td width='50%'>Altitude:</td><td><input type='text' name='altitude' value='$altitude'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "<input type='hidden' name='city_id' value='$city_id'>";
  print "</table>";
  print "</form>";
  print "<td>";
    print "<div align='center'>
	      <div id='mapgoogle' style='width: 100%; height: 500px;'></div>
	  </div>";
  print "</tr></table>";	  
  print "<script>
  	  function checkForm(obj){
		var reg_city = /\^([a-z]+)\$/i;
		var reg_code = /\^([0-9]+)\$/i;
		var reg_latlng = /\^([0-9]+\.[0-9]+)\$\|0/i;
		var reg_alt = /\^([0-9]+)\$\|0\|\^-([0-9]+)\$/i;
		    if (obj.city_name.value == '')
		    {
			alert ('Please enter City.');
			return false;
		    }
		    else
		    {
			if (reg_city.exec(obj.city_name.value) == null)
			{
			alert ('Please enter right City name.');
			return false;
			}
		    }
		      if (obj.phone_code.value)
		      {
			if (reg_code.exec(obj.phone_code.value) == null)
			{
			  alert ('Please enter right phone code.');
			  return false;
			}
		      }
		    if (reg_latlng.exec(obj.latitude.value) == null)
		    {
		      alert ('Please enter right latitude.');
		      return false;
		    }
		    if (reg_latlng.exec(obj.longitude.value) == null)
		    {
		      alert ('Please enter right longitude.');
		      return false;
		    }
		    if (reg_alt.exec(obj.altitude.value) == null)
		    {
		      alert ('Please enter right altitude.');
		      return false;
		    }
                }
         </script>";

    if ($latitude != 0 && $longitude != 0)
    {
      $lat=$latitude;
      $lng=$longitude;
    }
    else
    {
      $lat=40.363288;
      $lng=47.647705;
    }
      $latlng=$lat.",".$lng;
      print "<script src='http://maps.google.com/maps?file=api&amp;v=3.1&amp;key=ABQIAAAAm9GBs0LnKYd_egF6O197pRQ_nWHbqa19EWGxjZIiSnCLv3hmpRQfKkqCMm0gH3Dk-R_b_N3pZ81nmg' type='text/javascript' encoding='utf-8'></script>
		<script type='text/javascript'>
		//<![CDATA[
	  
		function load()
		{
		  if (GBrowserIsCompatible())
		  {
		    var pntx=$lng;
		    var pnty=$lat;
		    var center = new GLatLng(pnty, pntx);
		    var map = new GMap2(document.getElementById('mapgoogle'));
		    var map_ctrl=new GLargeMapControl();
		    var map_type_ctrl=new GMapTypeControl();
		    var map_scale_ctrl=new GScaleControl();
		    var latlng = new GLatLng($latlng);
		    var marker = new GMarker(latlng);
		      map.addControl(map_ctrl);
		      map.addControl(map_type_ctrl);
		      map.addControl(map_scale_ctrl);
		      map.setCenter(center, 7, G_HYBRID_MAP);
		      map.addOverlay(marker);
		      GEvent.addListener(map, 'click', function(overlay,latlng)
		      {
			if (latlng)
			{
			  var t = latlng.toString();
			    map.removeOverlay(marker);
			    marker = new GMarker(latlng);
			    map.addOverlay(marker);
			    add_city.latitude.value=t.slice(1,+10);			  
			    add_city.longitude.value=t.slice(t.indexOf(',')+2,t.indexOf(',')+11);
			    GDownloadUrl('altitude.pl?lat='+latlng.lat()+'&lng='+latlng.lng(), function(data) {
			    add_city.altitude.value=data;
			    });
			}
		      });
		  }
		}
	      //]]>
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
		document.location.href='city.pl';
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
