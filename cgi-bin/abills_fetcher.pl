#!/usr/bin/perl
use warnings;
use utf8;

require 'configurations.pl';

use DBI;
use Date::Calc qw /Days_in_Month/;


#connect to mysql
my $abills_dbh = DBI->connect("dbi:mysql:host=$abills_host;database=$abills_db", $abills_username, $abills_password);
#turn on unicode
$abills_dbh->do("set names 'utf8'");

sub abills_deposit_time_fetcher($)
{
    my $ext_bill_id = $_[0];

    my $abills_sql=$abills_dbh->prepare("SELECT uid FROM users u WHERE ext_bill_id=$ext_bill_id");
    $abills_sql->execute();
    my $uid = $abills_sql->fetchrow_array;
    
    $abills_sql = $abills_dbh->prepare("SELECT deposit FROM bills WHERE uid = $uid order by id desc");
    $abills_sql->execute();
    my ($balance,$_) = $abills_sql->fetchrow;
    
    $abills_sql = $abills_dbh->prepare("SELECT tp.month_fee FROM dv_main dv LEFT JOIN tarif_plans tp ON ( dv.tp_id = tp.id )  WHERE uid= $uid");
    $abills_sql->execute();
    my $month_fee = $abills_sql->fetchrow;

    my ($_,$_,$_,$_,$month,$year,$_,$_,$_) = localtime(time);

    my $days_in_month = Days_in_Month( $year, $month);
    
    my $days_to_block;
    if ($balance ==0 or not defined($balance) )
    { 
	$days_to_block = 'N/A';
    }
    else
    {
	$days_to_block = $balance / (  $month_fee / $days_in_month ) ;  
    }
    #rounding the number
    return  int($days_to_block) ;
}

sub abills_user_info()
{
    my $ext_bill_id = $_[0];

    my $abills_sql=$abills_dbh->prepare("SELECT id FROM users u WHERE ext_bill_id=$ext_bill_id");
    $abills_sql->execute();
    my $login = $abills_sql->fetchrow_array;
    
    return $login;

}

sub abills_user_balance()
{
	my $ext_bill_id = $_[0];
	my $with_html = $_[1];
	
	my $abills_sql=$abills_dbh->prepare("SELECT uid FROM users u WHERE ext_bill_id=$ext_bill_id");
	$abills_sql->execute();
	my $uid = $abills_sql->fetchrow_array;

	
	$abills_sql = $abills_dbh->prepare("SELECT date,sum,dsc,name,p.uid FROM payments p
						  LEFT JOIN users u ON (u.uid=p.uid)
						  LEFT JOIN admins a ON (a.aid=p.aid) 
						  WHERE u.uid = $uid");
	$abills_sql->execute();

	
	if ($with_html eq 'with_html')
	{
	    print "<form>";
	    print "<tr><td colspan='3'>From abills payments Info:<br>";
	    print "<table width='100%' border='1' cellspacing='1' cellpadding='1' align='left'>";
	    print "<tr><th>Date<th>Amount<th>Description<th>admin name<td width='1%'>&nbsp;";
	
	    while ( ($date,$sum,$dsc,$name) = $abills_sql->fetchrow_array )
	    {
		if ($dsc eq '') { $dsc= 'manual added';}
		print "<tr><td>$date<td>$sum<td>$dsc<td>$name</tr>";
	    }

    	    $abills_sql = $abills_dbh->prepare("SELECT deposit FROM bills WHERE uid = $uid order by id desc");
	    $abills_sql->execute();
	    my ($balance,$_) = $abills_sql->fetchrow;

       
	    print "<tr><th><b>Balance from abills :  $balance </b> AZN<td><td><td></form>";
	    print "<th><input type=button onClick=\"location.href='$abills_address?UID=$uid&index=2'\" value='Add or Delete'></tr>";
	    print "</table>";
	}
	else 
	{
       	    $abills_sql = $abills_dbh->prepare("SELECT deposit FROM bills WHERE uid = $uid order by id desc");
	    $abills_sql->execute();
	    my ($balance,$_) = $abills_sql->fetchrow;

	    return $balance ;
	};
}

sub abills_payments($)
{
    my $ext_bill_id = shift;
    my @payments;

    my $abills_sql=$abills_dbh->prepare("SELECT uid FROM users u WHERE ext_bill_id=$ext_bill_id");
    $abills_sql->execute();
    my $uid = $abills_sql->fetchrow_array;

    $abills_sql = $abills_dbh->prepare("SELECT date,sum,dsc,amount,name,p.uid FROM payments p
						  LEFT JOIN users u ON (u.uid=p.uid)
						  LEFT JOIN admins a ON (a.aid=p.aid) 
						  WHERE u.uid = $uid order by date desc");
    $abills_sql->execute();

    while (my  ($date,$sum,$dsc,$amount,$name) = $abills_sql->fetchrow_array )
    {
       if ($dsc eq '') { $dsc= 'manual added';}
          push (@payments , "$date $sum $dsc $amount, $name "); 
    }
     return @payments;
       
}
