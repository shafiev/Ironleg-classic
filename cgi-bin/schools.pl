#!/usr/bin/perl

use DBI;
use MIME::Base64;
use CGI qw(:standard);  
use CGI::Carp qw(fatalsToBrowser);
use utf8;
use Data::Dumper;

my $action=param('action');
my $page=param('page');
my $rows=param('rows');
my $school_id=param('school_id');
my $school_code=param('school_code');
my $city_id=param('city_id');
my $type_id=param('type_id');
my $city_id_new=param('city_id_new');
my $city_latitude=param('city_latitude');
my $city_longitude=param('city_longitude');
my $latitude=param('latitude');
my $longitude=param('longitude');
my $altitude=param('altitude');
my $school_name=param('school_name');
my $address=param('address');
my $description=param('description');
my $s_city_name=param('s_city_name');
my $s_type_name=param('s_type_name');
my $s_school_name=param('s_school_name');
my $s_address=param('s_address');
my $s_search=param('s_search');
my $s_type=param('s_type');
my $s_desc=param('s_desc');


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
$table="schools_v";
$ENV{'NLS_LANG'}="AMERICAN_AMERICA.AL32UTF8";
$db = DBI->connect("dbi:Oracle:host=$db;sid=$dbsid", $dbuser, $dbpass,{ora_ncharset => 'AL32UTF8'});


$sql0=$db->prepare(qq{SELECT Privilege 
		      FROM user_tab_privs
		      WHERE owner = upper('$schema')
		      AND Grantee = upper('$dbuser')
		      AND Table_Name = upper('$table')
		      UNION
		      SELECT Privilege
		      FROM role_tab_privs
		      WHERE owner = upper('$schema')
		      AND Table_name = upper('$table')});
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
    print "<a href='schools.pl?action=show_map'>Map</a>
	   <a href='schools.pl?action=search_page'>Search by mac and phone and etc</a>";
    print "<table  width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><th width=1%>N</th>
	       <th>City</th>
	       <th>Type</th>
	       <th>Code</th>
	       <th>School</th>
	       <th>Address</th>
               <th>DHCP IP</th>
               <th>Connection Type</th>
               <th>Provider Name</th>
	       <th>Latitude</th>
	       <th>Longitude</th>
	       <th>Altitude</th>
	       <th>Description</th>
	       <th>&nbsp;
	   </tr>";
    print "<form method=post>";
    print "<tr>
	      <td>&nbsp;</td>
	      <td><input type=text name='s_city_name' value='$s_city_name' size=9></td>
	      <td><input type=text name='s_type_name' value='$s_type_name' size=20></td>
	      <td>&nbsp;</td>
	      <td><input type=text name='s_school_name' value='$s_school_name' size=30></td>
	      <td><input type=text name='s_address' value='$s_address' size=30></td>
	      <td>&nbsp;</td>
	      <td>&nbsp;</td>
              <td>&nbsp;</td>
              <td>&nbsp;</td>
              <td>&nbsp;</td>
              <td>&nbsp;</td>
	      <td><input type=text name='s_desc' value='$s_desc' size=30></td>
	      <td><input type=submit value='Search'></td>
	   </tr>";
    print "<input type=hidden name='rows' value='$rows'>";
    print "</form>";

    $select = "SELECT *
	       FROM $schema.$table
	       WHERE 1=1";
      if ($s_city_name)
      {
	$select .= " AND upper(city_name) like upper('%$s_city_name%')";
      }
      if ($s_type_name)
      {
	$select .= " AND upper(type_name) like upper('%$s_type_name%')";
      }
      if ($s_school_name)
      {
	$select .= " AND upper(name) like upper('%$s_school_name%')";
      }
      if ($s_address)
      {
	$select .= " AND upper(address) like upper('%$s_address%')";
      }
      if ($s_desc)
      {
	$select .= " AND upper(description) like upper('%$s_desc%')";
      }	      
    $select .= " ORDER BY city_name, name";
      if ($page eq ''){$page=1}
      if ($rows eq ''){$rows=20}
    $f_page=($page-1)*$rows+1;
    $l_page=$f_page+$rows-1;
    $sql0=$db->prepare(qq{SELECT s.rw, s.id, s.code, s.name, s.city_name, s.type_name, s.latitude, s.longitude, s.altitude, s.address, s.description, s.dhcp_ip
			  FROM (SELECT rownum rw, s.*
				FROM ($select) s
				WHERE rownum <= $l_page
			       ) s
			  WHERE s.rw >= $f_page});

    $sql0->execute();

    print "<form method='post' onsubmit='return func(this);'>";
      while(my($rownum,$school_id, $school_code, $school_name,$city_name,$type_name,$s_latitude,,$s_longitude,$s_altitude,$address,$description, $dhcp_ip) = $sql0->fetchrow_array)
      {
=vizov connection type and prov name
 
=cut
   my ($con_type_name,$prov_name) = connection_type_and_prov_name_fetch($school_id);

	print "<tr>
		<td>$rownum</td>
		<td>$city_name</td>
		<td>$type_name</td>
		<td>$school_code &nbsp;</td>
		<td><a href='schools_info.pl?school_id=$school_id'>$school_name</a></td>
		<td>$address &nbsp;</td>
                <td>$dhcp_ip &nbsp</td>
                <td>$con_type_name</td>
                <td>$prov_name</td>
		<td>$s_latitude</td>
		<td>$s_longitude</td>
		<td>$s_altitude</td>
		<td>$description &nbsp;</td>
		<td width=10><input type='radio' name='school_id' value='$school_id'></td>
	       </tr>";
      }
      $select =~ s/(\SELECT).*/$1 count(*)/;
      $select =~ s/(ORDER.*)//s;
      my $sql1 = $db->prepare($select);
      $sql1->execute;
      my ($eq_count) = $sql1->fetchrow_array;
      my $page_numb = $eq_count/$rows;
      $page_numb =~ s/(\d+).*/$1+1/e;
      print "<tr><td colspan=2><b>Total: $eq_count";
      print "<td colspan=7><center>";
	for (my $i=1 ;$i<=$page_numb ;++$i)
	{
	  if ($page==$i){ print " $i"}
	  else {print " <a href='schools.pl?page=$i&rows=$rows&s_city_name=$s_city_name&s_type_name=$s_type_name&s_school_name=$s_school_name&s_address=$s_address&s_desc=$s_desc'>$i</a>";}
	}
      print "</center>";
	print "<td colspan=2 align=right><select 
	    onchange=\"if (this.options[this.selectedIndex].value == '') 
	    this.selectedIndex=0; 
	    else window.open(this.options[this.selectedIndex].value,'_top')\">";
	  if ($rows == 20){$sl = "selected"}else{$sl = ""}
        print "<option value='?page=$i&rows=20&s_city_name=$s_city_name&s_type_name=$s_type_name&s_school_name=$s_school_name&s_address=$s_address&s_desc=$s_desc' $sl>20</option>";
	  if ($rows == 50){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=50&s_city_name=$s_city_name&s_type_name=$s_type_name&s_school_name=$s_school_name&s_address=$s_address&s_desc=$s_desc' $sl>50</option>";
	  if ($rows == 100){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=100&s_city_name=$s_city_name&s_type_name=$s_type_name&s_school_name=$s_school_name&s_address=$s_address&s_desc=$s_desc' $sl>100</option>";
	  if ($rows == 100000){$sl = "selected"}else{$sl = ""}
	print "<option value='?page=$i&rows=100000&s_city_name=$s_city_name&s_type_name=$s_type_name&s_school_name=$s_school_name&s_address=$s_address&s_desc=$s_desc' $sl>All</option>";
        print "</select>";
      if ($privs_list =~ /INSERT|UPDATE|DELETE/)
      {
      print "<tr><td colspan=12>";
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
	    var school_id_length = obj.school_id.length;
		if (obj.action.value == 'edit')
		{
		  if (!school_id_length)
		  {
		    if (obj.school_id.checked == true)
		    {
		     return true;
		    }
		  }
		  else
		  {
		    for (var i=0; i<school_id_length;i++)
		    {
		      if (obj.school_id[i].checked == true)
		      {
		       return true;
		      }
		    }
		  }
		  alert('Choose school.');
		  return false;
		}
		if (obj.action.value == 'delete')
		{
		  if (!school_id_length)
		  {
		    if (obj.school_id.checked == true)
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
		    for (var i=0; i<school_id_length;i++)
		    {
		      if (obj.school_id[i].checked == true)
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
		  alert('Choose school.')
		  return false;
		}
		}		
	    </script>";
    }
    else
    {
      print "<br>Insufficient privileges";
    }
  }
  elsif ($action eq "add")
  {
    &add_edit_form($action);
  }
  elsif($action eq "add_db")
  {
      if ($school_name !~ /[()\%\'\*\\]/i && $school_code !~ /[()\%\'\*\\]/i && $city_id =~ /^\d+$/ && $type_id =~ /^\d+$/ && $address !~ /[()\%\'\*\\]/i && $description !~ /[()\%\'\*\\]/i && $latitude =~ /^\d+\.\d+$|0|^\d+.+?\d+\'\d+\".$/ && $longitude =~ /^\d+\.\d+$|0|^\d+.+?\d+\'\d+\".$/ && $altitude =~ /^\d+$|0|^-\d+$/)
      {
	  if ($latitude =~ /^(\d+).+?(\d+)\'(\d+)\"/)
	    {
	      $q = $3/60;
	      $w = ($2+$q)/60;
	      $latitude = sprintf("%.6f", $1+$w);
	    }
	  if ($longitude =~ /^(\d+).+?(\d+)\'(\d+)\"/)
	    {
	      $q = $3/60;
	      $w = ($2+$q)/60;
	      $longitude = sprintf("%.6f", $1+$w);
	    }
	$query = "INSERT into $schema.$table(code,name,city_id,type_id,address,latitude,longitude,altitude,description)
		  VALUES(UPPER('$school_code'),INITCAP('$school_name'),$city_id,$type_id,'$address','$latitude','$longitude','$altitude','$description')";
	$redirect = "?action=add&school_name=$school_name&city_id=$city_id&longitude=$longitude&latitude=$latitude&altitude=$altitude&address=$address&description=$description";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit")
  {
      if ($school_id =~ /^\d+$/)
      {
      &add_edit_form($action,$school_id)
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "edit_db")
  {
      if ($school_id =~ /^\d+$/ && $school_code !~ /[()\%\'\*\\]/i && $school_name !~ /[()\%\'\*\\]/i && $city_id =~ /^\d+$/ && $type_id =~ /^\d+$/ && $address !~ /[()\%\'\*\\]/i && $description !~ /[()\%\'\*\\]/i && $latitude =~ /^\d+\.\d+$|0|^\d+.+?\d+\'\d+\".$/ && $longitude =~ /^\d+\.\d+$|0|^\d+.+?\d+\'\d+\".$/ && $altitude =~ /^\d+$|0|^-\d+$/)
      {
	  if ($latitude =~ /^(\d+).+?(\d+)\'(\d+)\"/)
	    {
	      $q = $3/60;
	      $w = ($2+$q)/60;
	      $latitude = sprintf("%.6f", $1+$w);
	    }
	  if ($longitude =~ /^(\d+).+?(\d+)\'(\d+)\"/)
	    {
	      $q = $3/60;
	      $w = ($2+$q)/60;
	      $longitude = sprintf("%.6f", $1+$w);
	    }
	$query = "UPDATE $schema.$table
		  SET name = INITCAP('$school_name'),
		      code = UPPER('$school_code'),
		      city_id = $city_id,
		      type_id = $type_id,
		      address = '$address',
		      latitude = '$latitude',
		      longitude = '$longitude',
		      altitude = '$altitude',
		      description = '$description'
		  WHERE id='$school_id'";
	$redirect = "?action=edit&school_id=$school_id";
	&add_edit_del_db($query,$redirect);
      }
      else
      {
	print "Error";
      }
  }
  elsif($action eq "delete")
  {
    if ($school_id =~ /^\d+$/)
    {
      $query = "DELETE from $schema.$table WHERE id='$school_id'";
      $redirect = "?";
      &add_edit_del_db($query,$redirect);
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
			       WHERE rownum <= 1");
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
	  print "<option value='schools.pl?action=show_map&city_id=$id&city_latitude=$city_latitude&city_longitude=$city_longitude' $sl>$city</option>";
      }
    print "</select></div>";

    print "<div align='center'>
	      <div id='mapgoogle' style='width: 100%; height: 600px;'></div>
	  </div>";
    &show_map($city_latitude,$city_longitude,$ats_latitude,$ats_longitude);
  }
  elsif ($action eq "search_page")
  {
    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='right'>";
    print "<tr><td width='30%' valign=top><table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
    print "<form method=get>";
    print "<tr><td width=50%>Search: <td><input type=text name='s_search' value='$s_search'>";
    print "<tr><td>Where: <td width=50%><select name='s_type'>";
    print "<option value='ip'"; if ($s_type eq "ip") {print " selected"} print " >IP Address</option>";
    print "<option value='mac'"; if ($s_type eq "mac") {print " selected"} print " >MAC Address</option>";
    print "<option value='phone'"; if ($s_type eq "phone") {print " selected"} print " >Phone Number</option>";
    print "</select>";
    print "<input type=hidden name='action' value='search_page'>";
    print "<tr><td>&nbsp;<td><input type=submit>";
    print "</form>";
    print "</table>";
    print "<td valign=top><table width=100% border='1' cellspacing='1' cellpadding='1' valign=top>";
    print "<tr><th>City<th>Type<th>School";
    $select = "SELECT s.id,aep.city_name,aep.school_name,s.type_name
	       FROM $schema.ats_eq_ports_v aep inner join $schema.schools_v s
	       ON aep.school_id = s.id";
      if ($s_type eq "ip")
      {
	  $select .= " WHERE aep.ip LIKE '%$s_search%'";

      }
      elsif ($s_type eq "phone")
      {
	$select .= " WHERE aep.phone LIKE '%$s_search%'";
      }
      elsif ($s_type eq "mac")
      {
	      $s_search = uc($s_search);
	      $s_search =~ s/\://g;
	      $s_search =~ s/\.//g;
	$select = "SELECT s.id,s.city_name,se.school_name,s.type_name
		   FROM $schema.schools_eq_v se inner join $schema.schools_v s
		   ON se.school_id = s.id
		   WHERE upper(se.mac) LIKE '%$s_search%'";
      }
    my $sql0 = $db->prepare($select);
    $sql0->execute;
      while (my($school_id,$city_name,$school_name,$type_name) = $sql0->fetchrow_array)
      {
	print "<tr><td>$city_name<td>$type_name<td><a href='schools_info.pl?school_id=$school_id'>$school_name</a>";
      }
    print "</table>";
  }
sub add_edit_form
{
  my($action,$school_id) = @_;
    if ($action eq "edit")
    {
    my $sql0 = $db->prepare("SELECT code,name,city_id,type_id,address,latitude,longitude,altitude,description,city_latitude,city_longitude
			     FROM $schema.$table
			     WHERE id='$school_id'");
    $sql0->execute;
    ($school_code,$school_name,$city_id,$type_id,$address,$latitude,$longitude,$altitude,$description,$city_latitude,$city_longitude) = $sql0->fetchrow_array;
    }
    if ($city_id_new){$city_id=$city_id_new}
  print "<form name='edit_ats' method='get' onsubmit='return checkForm(this);'>";
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
	print "<option value='schools.pl?action=$action&school_id=$school_id&city_id_new=$id&city_latitude=$city_latitude&city_longitude=$city_longitude&city_altitude=$city_altitude&ats_address=$ats_address&cross_cable=$cross_cable' $sl>$city</option>";
    }
  print "</select></td></tr>";
  print "<tr><td width='50%'>School Code:</td><td><input type='text' name='school_code' value='$school_code'>";
  print "<tr><td width='50%'>School Name:</td><td><input type='text' name='school_name' value='$school_name'>";
  print "<tr><td>Client Type:<td><select name='type_id'>";
  my $sql0 = $db->prepare("SELECT id,name
                           FROM $schema.clients_type_v
                           ORDER BY name");
  $sql0->execute;
    while (my($id,$name) = $sql0->fetchrow_array)
    {
        if ($type_id eq $id) {$sl="selected"}
        else {$sl=""}
        print "<option value='$id' $sl>$name</option>";
    }
  print "</select>";
  print "<tr><td width='50%'>Address:</td><td><input type='text' name='address' value='$address'>";
    if (!$latitude){$latitude=0}
    if (!$longitude){$longitude=0} 
    if (!$altitude){$altitude=0}
  print "<tr><td width='50%'>Latitude:</td><td><input type='text' name='latitude' value='$latitude'>";
  print "<tr><td width='50%'>Longitude:</td><td><input type='text' name='longitude' value='$longitude'>";
  print "<tr><td width='50%'>Altitude:</td><td><input type='text' name='altitude' value='$altitude'>";
  print "<tr><td width='50%'>Description:</td><td><input type='text' name='description' value='$description'>";
  print "<tr><td>&nbsp;</td><td><input type='submit' value='Submit'>";
  print "<input type='hidden' name='school_id' value='$school_id'>";
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
  
  &show_map($city_latitude,$city_longitude,$latitude,$longitude);

  print "<script>
	  function checkForm(obj)
	    {
	      var reg_exp = /[()\%\'\*]/;
	      var reg_cable = /\^([0-9]+)\$\|\^\$/i;
	      var reg_latlng = /\^([0-9]+\.[0-9]+)\$\|0|([0-9]+.[0-9]*\'.[0-9]*\".*)\$\/i;
	      var reg_alt = /\^([0-9]+)\$\|0\|\^-([0-9]+)\$/i;
		if (obj.school_name.value == '')
		{
		  alert ('Please enter School name.');
		  return false;
		}
		else
		{
		  if (reg_exp.exec(obj.school_name.value) != null)
		  {
		  alert ('Please enter right School name.');
		  return false;
		  }
		}
		if (reg_exp.exec(obj.address.value) != null)
		{
		alert ('Please enter right address.');
		return false;
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
}

sub show_map
{
  my($city_latitude,$city_longitude,$ats_latitude,$ats_longitude) = @_;
  
    if ($ats_latitude != 0 && $ats_longitude !=0)
    {
      $lat=$ats_latitude;
      $lng=$ats_longitude;
      $zoom=16;      
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

  my $sql0 = $db->prepare("SELECT name, city_name, latitude,longitude,address
			   FROM $schema.$table
			   WHERE latitude <> 0
			   AND longitude <> 0");
  $sql0->execute;

  my $sql1 = $db->prepare("SELECT name,city_name,ats_latitude,ats_longitude,address
			   FROM $schema.ats_v
			   WHERE ats_latitude <> 0
			   AND ats_longitude <> 0");
  $sql1->execute;

  my $sql2 = $db->prepare("SELECT ats_latitude,ats_longitude,school_latitude,school_longitude
			   FROM $schema.ats_schools_latlng_v");
  $sql2->execute;
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
	      var schoolIcon = new GIcon(G_DEFAULT_ICON);
	      var atsIcon = new GIcon(G_DEFAULT_ICON);
	      blueIcon.image = 'http://ironleg.azedunet.az/blank.png';
	      schoolIcon.image = 'http://ironleg.azedunet.az/school.png';
	      atsIcon.image = 'http://ironleg.azedunet.az/ats.png';
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
		    edit_ats.latitude.value=t.slice(1,+10);
		    edit_ats.longitude.value=t.slice(t.indexOf(',')+2,t.indexOf(',')+11);
		    GDownloadUrl('altitude.pl?lat='+latlng.lat()+'&lng='+latlng.lng(), function(data) {
			    edit_ats.altitude.value=data;
		    });
		  }
		});

		function createMarker(latlng,info)
		{
		  var marker = new GMarker(latlng, {icon:schoolIcon});
		    GEvent.addListener(marker,'click', function()
		    {
		      marker.openInfoWindowHtml(info);
		    });
		return marker;
		}
		function createMarker1(latlng,info)
		{
		  var marker = new GMarker(latlng, {icon:atsIcon});
		    GEvent.addListener(marker,'click', function()
		    {
		      marker.openInfoWindowHtml(info);
		    });
		return marker;
		}		
		";
      
    while (($school_name,$city_name,$latitude,$longitude,$address) = $sql0->fetchrow_array)
    {
      $latlng=$latitude.",".$longitude;
      print "var latlng = new GLatLng($latitude, $longitude);";
      print "map.addOverlay(createMarker(latlng,'<b>School:</b> $school_name<br><b>Address:</b> $address'));";
    }

    while (($ats_name,$city_name,$ats_latitude,$ats_longitude,$ats_address) = $sql1->fetchrow_array)
    {
      $latlng=$ats_latitude.",".$ats_longitude;
      print "var latlng = new GLatLng($ats_latitude, $ats_longitude);";
      print "map.addOverlay(createMarker1(latlng,'<b>ATS:</b> $ats_name<br><b>Address:</b> $ats_address'));";
    }

    while (($ats_latitude,$ats_longitude,$school_latitude,$school_longitude) = $sql2->fetchrow_array)
    {
      $latlng1=$ats_latitude.",".$ats_longitude;
      $latlng2=$school_latitude.",".$school_longitude;
      print "var polyline = new GPolyline([new GLatLng($latlng1),
					    new GLatLng($latlng2)], '#ff0000', 2);";
      print "map.addOverlay(polyline);";

    }

  print"    }
	  }
    
	  //]]>
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
	$error = "School already exist.";
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


sub connection_type_and_prov_name_fetch($)
{
    my $school_id_for_sql_query= shift;
    my $sql_for_fetch_type= $db->prepare("select con_type_name , prov_name from ironleg.ats_eq_ports_v where ats_eq_ports_v.school_id = ?"); 
    
    $sql_for_fetch_type->execute($school_id_for_sql_query);
    my ($connection_type_name,$prov_name) = $sql_for_fetch_type->fetchrow_array;
    
    return $connection_type_name,$prov_name;
}
