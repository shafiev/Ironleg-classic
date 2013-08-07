#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);

my $action=param('action');
my $ats_id=param('ats_id');
my $city_id=param('city_id');
my $city_id_new=param('city_id_new');
my $ats_name=param('ats_name');
my $ats_latitude=param('ats_latitude');
my $ats_longitude=param('ats_longitude');
my $ats_altitude=param('ats_altitude');
my $city_latitude=param('city_latitude');
my $city_longitude=param('city_longitude');
my $ats_address=param('ats_address');
my $cross_cable=param('cross_cable');
my $s_city_name=param('s_city_name');
my $s_ats_name=param('s_ats_name');
my $s_ats_address=param('s_ats_address');
my $page=param('page');


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


#print "Hello $REMOTE_USER!";
       
$db="127.0.0.1";
$dbsid="IRONLEG";
$schema="ironleg";
$table="ats_v";
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
    
#print "$s_city_name";

  if ($action eq "")
  {
    if ($s_city_name !~ /['\\]/i && $s_ats_name !~ /['\\]/i && $s_ats_address !~ /['\\]/i)
    {
      if ($privs_list =~ /SELECT/)
      {
      print "<a href='ats.pl?action=show_map' target='_blank'>Map</a>";
      print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
      print "<tr><th width=1%>N</th>
		 <th width=10%>City</th>
		 <th width=10%>ATS</th>
		 <th width=25%>Address</th>
		 <th width=5%>Cable</th>
		 <th>Latitude</th>
		 <th>Longitude</th>
		 <th>Altitude</th>
		 <th>Equipment Count</th>
		 <th>Schools Count</th>
		 <th width=1%>&nbsp;
	     </tr>";
      print "<form method=post>";
      print "<tr>
		<td>&nbsp;</td>
		<td><input type=text name='s_city_name' value='$s_city_name' size=15></td>
		<td><input type=text name='s_ats_name' value='$s_ats_name' size=30></td>
		<td><input type=text name='s_ats_address' value='$s_ats_address' size=35></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td colspan=7 align=right><input type=submit value='Search'></td>
	     </tr>";
      print "</form>";
      $select = "SELECT id, name, city_name, ats_latitude, ats_longitude, ats_altitude, address, cross_cable, eq_count, schools_count
		 FROM  $schema.$table
		 WHERE 1=1";
	if ($s_city_name)
	{
	  $select .= " AND UPPER(city_name) like UPPER('%$s_city_name%')";
	}
	if ($s_ats_name)
	{
	  $select .= " AND UPPER(name) like UPPER('%$s_ats_name%')";
	}
	if ($s_ats_address)
	{
	  $select .= " AND UPPER(ats_address) like UPPER('%$s_ats_address%')";
	}
      $select .= " ORDER BY city_name, name";
	if ($page eq ''){$page=1}
      $f_page=($page-1)*20+1;
      $l_page=$f_page+19;
      $sql0=$db->prepare(qq{SELECT a.rw, id, name, city_name, ats_latitude, ats_longitude, ats_altitude, address, cross_cable, eq_count, schools_count
			    FROM (SELECT rownum rw, a.*
				  FROM ($select) a
				  WHERE rownum <= $l_page
				 ) a
			    WHERE a.rw >= $f_page});
      $sql0->execute();
      print "<form action='ats.pl' method='post' onsubmit='return func(this);'>";
	while(my($row_n,$ats_id,$ats_name,$city_name,$ats_latitude,$ats_longitude,$ats_altitude,$ats_address,$cross_cable,$eq_count,$schools_count) = $sql0->fetchrow_array)
	{
	  print "<tr>
		  <td>$row_n</td>
		  <td>$city_name</td>
		  <td><a href='ats_contacts.pl?ats_id=$ats_id'>$ats_name</a></td>
		  <td>&nbsp;$ats_address</td>
		  <td>&nbsp;$cross_cable</td>
		  <td>$ats_latitude</td>
		  <td>$ats_longitude</td>
		  <td>$ats_altitude</td>
		  <td><a href='ats_eq.pl?s_ats_name=$ats_name&s_city_name=$city_name'>$eq_count</td>
		  <td>$schools_count</td>";
	  print "	<td width=10><input type='radio' name='ats_id' value='$ats_id'></td>
		 </tr>";
	}
	  $select =~ s/(\SELECT).*/$1 count(*),sum(eq_count),sum(schools_count)/;
	  $select =~ s/(ORDER.*)//s;
	  my $sql1 = $db->prepare($select);
	  $sql1->execute;
	  ($eq_count,$sum_ec,$sum_sc) = $sql1->fetchrow_array;
	  my $page_numb = $eq_count/20;
	  $page_numb =~ s/(\d+).*/$1+1/e;
	  print "<tr><td colspan=2><b> Total: $eq_count";
	  print "<td colspan=6><center>";
	    for (my $i=1 ;$i<=$page_numb ;++$i)
	    {
	      if ($page==$i){ print " $i"}
	      else {print " <a href='ats.pl?page=$i&s_city_name=$s_city_name&s_ats_name=$s_ats_name&s_ats_address=$s_ats_address'>$i</a>";}
	    }
	  print "</center>";  
	print "<td><b>$sum_ec<td><b>$sum_sc<td>&nbsp;";
	if ($privs_list =~ /INSERT|UPDATE|DELETE/)
	{
	print "<tr><td colspan=12";
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
		var ats_id_length = obj.ats_id.length;
		  if (!ats_id_length)
		  {
		    ats_id_length = 1;
		  }
		  if (obj.action.value == 'edit')
		  {
		    for (var i=0; i<ats_id_length;i++)
		    {
		      if (obj.ats_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		    alert('Choose ATS.')
		    return false;
		  }
		  if (obj.action.value == 'delete')
		  {
		    for (var i=0; i<ats_id_length;i++)
		    {
		      if (obj.ats_id[i].checked == true)
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
		    alert('Choose ATS')
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
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "add")
  {
    &add_edit_form($action)
  }
  elsif($action eq "add_db")
  {
    if ($ats_name !~ /[()\%\'\*\s]/i && $cross_cable =~ /^\d+$|/ && $ats_address !~ /[()\%\'\*\s]/i && $city_id =~ /^\d+$/ && $ats_latitude =~ /^\d+\.\d+$|0/ && $ats_longitude =~ /^\d+\.\d+$|0/ && $ats_altitude =~ /^\d+$|0|^-\d+$/)
    {
      $query = "INSERT into $schema.$table(name,city_id,ats_latitude,ats_longitude,ats_altitude,address,cross_cable)
		VALUES(upper('$ats_name'),'$city_id',$ats_latitude,$ats_longitude,$ats_altitude,'$ats_address','$cross_cable')";
      $redirect = "ats.pl?action=add&ats_name=$ats_name&city_id=$city_id&ats_latitude=$ats_latitude&ats_longitude=$ats_longitude&ats_altitude=$ats_altitude&ats_address=$ats_address&cross_cable=$cross_cable";
      &add_edit_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "edit")
  {
    if ($ats_id =~ /^\d+$/)
    {
      &add_edit_form($action,$ats_id)
    }
    else
    {
      print "Error";
    }
  }
  elsif($action eq "edit_db")
  {
      if ($ats_id =~ /^\d+$/ && $ats_name !~ /[()\%\'\*\s]/i && $cross_cable =~ /^\d+$|/ && $ats_address !~ /[()\%\'\*\s]/i && $city_id =~ /^\d+$/ && $ats_latitude =~ /^\d+\.\d+$|0/ && $ats_longitude =~ /^\d+\.\d+$|0/ && $ats_altitude =~ /^\d+$|0|^-\d+$/)
      {
	$query = "UPDATE $schema.$table
		  SET name = upper('$ats_name'),
		      city_id = '$city_id',
		      ats_latitude = $ats_latitude,
		      ats_longitude = $ats_longitude,
		      ats_altitude = $ats_altitude,
		      cross_cable = '$cross_cable',
		      address = '$ats_address'
		  WHERE id = '$ats_id'";
	$redirect = "ats.pl?action=edit&ats_id=$ats_id";
	&add_edit_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($ats_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$ats_id'";
      $redirect = "ats.pl";
      &add_edit_db($query,$redirect);
    }
    else
    {
      print "Error";
    }
  }
  elsif ($action eq "show_map")
  {
    if (!$city_id)
    {
      my $sql0 = $db->prepare("SELECT id,latitude,longitude
			       FROM $schema.city_v
			       WHERE rownum <= 1
			       ORDER BY name");
      $sql0->execute;
      ($city_id,$city_latitude,$city_longitude) = $sql0->fetchrow_array;
    }

    print "<div align=right>City:";
    print "<select name='city_select'
	      onchange=\"if (this.options[this.selectedIndex].value == '') 
	      this.selectedIndex=0; 
	      else window.open(this.options[this.selectedIndex].value,'_top')\">";
    my $sql0 = $db->prepare("SELECT id,name,latitude,longitude
			     FROM $schema.city_v
			     ORDER BY name");
    $sql0->execute;
      while (my($id,$city,$city_latitude,$city_longitude) = $sql0->fetchrow_array)
      {
	  if ($city_id eq $id){$sl = "selected"}
	  else {$sl = ""}
	  print "<option value='ats.pl?action=show_map&city_id=$id&city_latitude=$city_latitude&city_longitude=$city_longitude' $sl>$city</option>";
      }
    print "</select></div>";

    print "<div align='center'>
	      <div id='mapgoogle' style='width: 100%; height: 600px;'></div>
	  </div>";
    &show_map($city_latitude,$city_longitude,$ats_latitude,$ats_longitude);
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

sub add_edit_form
{
  my($action,$ats_id) = @_;
    if ($action eq "edit")
    {
    my $sql0 = $db->prepare("SELECT name,city_id,ats_latitude,ats_longitude,ats_altitude,address,cross_cable,city_latitude,city_longitude
			     FROM $schema.$table
			     WHERE id='$ats_id'");
    $sql0->execute;
    ($ats_name,$city_id,$ats_latitude,$ats_longitude,$ats_altitude,$ats_address,$cross_cable,$city_latitude,$city_longitude) = $sql0->fetchrow_array;
    }
    if ($city_id_new){$city_id=$city_id_new}
  print "<form action='ats.pl' name='edit_ats' method='get' onsubmit='return checkForm(this);'>";
  print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  print "<tr><td width=30% valign=top><table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
  
    if (!$city_id_new && !$city_id)
    {
      my $sql0 = $db->prepare("SELECT c.*
			       FROM (SELECT id,latitude,longitude
				     FROM $schema.city_v
				     ORDER BY name) c
			       WHERE rownum <= 1");
      $sql0->execute;
      ($city_id,$city_latitude,$city_longitude) = $sql0->fetchrow_array;
    }
    
  print "<tr><td>City:";
  print "<td><select name='city_select'
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
  my $sql0 = $db->prepare("SELECT id,name,latitude,longitude
			   FROM $schema.city_v
			   ORDER BY name");
  $sql0->execute;
    while (my($id,$city,$city_latitude,$city_longitude) = $sql0->fetchrow_array)
    {
	if ($city_id eq $id){$sl = "selected"}
	else {$sl = ""}
	print "<option value='ats.pl?action=$action&ats_id=$ats_id&city_id_new=$id&city_latitude=$city_latitude&city_longitude=$city_longitude&city_altitude=$city_altitude&ats_address=$ats_address&cross_cable=$cross_cable' $sl>$city</option>";
    }
  print "</select></td></tr>";
  print "<tr><td width='50%'>ATS:</td><td><input type='text' name='ats_name' value='$ats_name'>";
  print "<tr><td width='50%'>ATS Address:</td><td><input type='text' name='ats_address' value='$ats_address'>";
  print "<tr><td width='50%'>Cross Cable:</td><td><input type='text' name='cross_cable' value='$cross_cable'>";
    if (!$ats_latitude){$ats_latitude=0}
    if (!$ats_longitude){$ats_longitude=0} 
    if (!$ats_altitude){$ats_altitude=0}
  print "<tr><td width='50%'>ATS Latitude:</td><td><input type='text' name='ats_latitude' value='$ats_latitude'>";
  print "<tr><td width='50%'>ATS Longitude:</td><td><input type='text' name='ats_longitude' value='$ats_longitude'>";
  print "<tr><td width='50%'>ATS Altitude:</td><td><input type='text' name='ats_altitude' value='$ats_altitude'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  print "<input type='hidden' name='ats_id' value='$ats_id'>";
  print "<input type='hidden' name='city_id' value='$city_id'>";
  $action .= "_db";
  print "<input type='hidden' name='action' value='$action'>";
  print "</table>";
  print "</form>";
  print "<td>";
  print "<div align='center'>
	      <div id='mapgoogle' style='width: 100%; height: 500px;'></div>
	  </div>";
  print "</tr></table>";
  
  &show_map($city_latitude,$city_longitude,$ats_latitude,$ats_longitude);

  print "<script>
	  function checkForm(obj)
	    {
	      var reg_exp = /[()\%\'\*]/;
	      var reg_cable = /\^([0-9]+)\$\|\^\$/i;
	      var reg_latlng = /\^([0-9]+\.[0-9]+)\$\|0/i;
	      var reg_alt = /\^([0-9]+)\$\|0\|\^-([0-9]+)\$/i;
		if (obj.ats_name.value == '')
		{
		  alert ('Please enter ATS name.');
		  return false;
		}
		else
		{
		  if (reg_exp.exec(obj.ats_name.value) != null)
		  {
		  alert ('Please enter right ATS name.');
		  return false;
		  }
		}
		if (reg_exp.exec(obj.ats_address.value) != null)
		{
		alert ('Please enter right ATS address.');
		return false;
		}

		if (reg_cable.exec(obj.cross_cable.value) == null)
		{
		alert ('Please enter right cross cable.');
		return false;
		}

		if (reg_latlng.exec(obj.ats_latitude.value) == null)
		{
		alert ('Please enter right ATS latitude.');
		return false;
		}
		if (reg_latlng.exec(obj.ats_longitude.value) == null)
		{
		alert ('Please enter right ATS longitude.');
		return false;
		}
		if (reg_alt.exec(obj.ats_altitude.value) == null)
		{
		alert ('Please enter right ATS altitude.');
		return false;
		}
	    }
	 </script>";
}

sub add_edit_db
{
  my ($query,$redirect) = @_;
  $sql0=$db->prepare("$query");
    if ($sql0->execute)
    {
      print "<SCRIPT LANGUAGE='javascript'>
	       <!--
		document.location.href='ats.pl';
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
	$error = "ATS already exist.";
      }
	print "<SCRIPT LANGUAGE='javascript'>
		<!--
		  alert('$error');
		  document.location.href='$redirect';
		//-->   
		</SCRIPT>";
    }  

}

sub show_map
{
  my($city_latitude,$city_longitude,$ats_latitude,$ats_longitude) = @_;
  
    if ($ats_latitude != 0 && $ats_longitude !=0)
    {
      $lat=$ats_latitude;
      $lng=$ats_longitude;
      $zoom=12;      
    }
    elsif ($city_latitude != 0 && $city_longitude != 0)
    {
      $lat=$city_latitude;
      $lng=$city_longitude;
      $zoom=12;
    }
    else
    {
      $lat=40.363288;
      $lng=47.647705;
      $zoom=7;
    }

  my $sql0 = $db->prepare("SELECT name,city_name,ats_latitude,ats_longitude,address
			   FROM $schema.$table
			   WHERE ats_latitude <> 0
			   AND ats_longitude <> 0");
  $sql0->execute;

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
	      var marker1 = new GMarker(latlng);
	      var blueIcon = new GIcon(G_DEFAULT_ICON);
	      blueIcon.image = 'http://ironleg.azedunet.az/blank.png';
	      markerOptions = { icon:blueIcon };
		map.addControl(map_ctrl);
		map.addControl(map_type_ctrl);
		map.addControl(map_scale_ctrl);
		map.setCenter(center, $zoom, G_HYBRID_MAP);


		GEvent.addListener(map, 'click', function(overlay,latlng)
		{
		  if (latlng)
		  {
		    var t = latlng.toString();
		    map.removeOverlay(marker1);
		    map.removeOverlay(marker1);
		    marker1 = new GMarker(latlng,markerOptions);
		    map.addOverlay(marker1);
		    edit_ats.ats_latitude.value=t.slice(1,+10);
		    edit_ats.ats_longitude.value=t.slice(t.indexOf(',')+2,t.indexOf(',')+11);
		    GDownloadUrl('altitude.pl?lat='+latlng.lat()+'&lng='+latlng.lng(), function(data) {
			    edit_ats.ats_altitude.value=data;
		    });
		  }
		});

		function createMarker(latlng,info)
		{
		  var marker = new GMarker(latlng);
		    GEvent.addListener(marker,'click', function()
		    {
		      marker.openInfoWindowHtml(info);
		    });
		return marker;
		}";
    while (($ats_name,$city_name,$ats_latitude,$ats_longitude,$ats_address) = $sql0->fetchrow_array)
    {
      $latlng=$ats_latitude.",".$ats_longitude;
      print "var latlng = new GLatLng($ats_latitude, $ats_longitude);";
      print "map.addOverlay(createMarker(latlng,'$ats_name'));";
    }

  print"    }
	  }
    
	  //]]>
	  </script>";
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
