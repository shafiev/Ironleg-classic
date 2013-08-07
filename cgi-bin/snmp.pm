#package Ironleg_SNMP;
use Net::SNMP;
use warnings;
use Data::Dumper;
use SNMP::Info::Layer2::ZyXEL_DSLAM ;

require 'configurations.pl';

my $zyxel = new SNMP::Info(
                         AutoSpecify => 1,
                         Debug       => 1,
                         DestHost    => '10.17.33.253',
                         Community   => $community,
                         Version     => 1
                       )
    or die "Can't connect to DestHost.\n";
 
#my $class      = $l2->class();
print "SNMP::Info determined this device to fall under subclass : $class\n";


sub snmp_fetch_data_zyxel($)
{      
    my $ip = shift;
    my ($session, $error) = Net::SNMP->session(
	-hostname  => $ip,
	-community => $community,
	-timeout   => $snmp_timeout ,
	);

    if (!defined $session) {
	printf " ne podnalas ERROR: %s.\n", $error;
	    return 0;
    }



    if (int($g_slot) >= 3)
    {#then we have ies-5000
	$snmp_port=int($g_slot).($g_port);
    }
    else
    {
	$snmp_port=int($g_port);
    }
    
    
    $port_status =  $session->get_request(-varbindlist => [ $snmp_port_enable_disable_prefix.$snmp_port],);
    ($_,$port_status) = %$port_status;
    if ($port_status == 1) { $port_status = 'Enabled/Включен'} else { $port_status = 'Disabled/ВЫключен'};
    if (!($port_status)) {         printf "ERROR: %s.\n", $session->error(); }

    #getting SNR params.
    $snr_upstream =  $session->get_request(-varbindlist => [ $snmp_snr_upstream.$snmp_port],);
    ($_,$snr_upstream) = %$snr_upstream;
    $snr_downstream = $session->get_request(-varbindlist => [$snmp_snr_downstream.$snmp_port] ,); 
    ($_,$snr_downstream) = %$snr_downstream;
    
    #getting profile with speed on the port
    $actual_profile = $session->get_request(-varbindlist => [$snmp_profile_change_prefix.$snmp_port] ,);
    ($_,$actual_profile ) = %$actual_profile;



    if ( $snr_downstream >= 290  ) 
    {
	$line_quality = 'Отличная линия.Может поддержать и VDSL2+ ';
    }
    if ( $snr_downstream >= 200 and $snr_downstream < 290  ) 
    {
	$line_quality = 'Очень хорошая линия ';
    }
    if ( $snr_downstream >= 100 and $snr_downstream < 200  ) 
    {
	$line_quality = 'Средний уровень линии,без проблем с синхронизацией';
    }
    if ( $snr_downstream < 100 and $snr_downstream > 70  ) 
    {
	$line_quality = 'Возможны сбои';
    }
    if ( $snr_downstream < 70 ) 
    {
	$line_quality = 'Очень плохая линия, присутствуют проблемы синхронизации';
    }
    
    if ($snr_downstream == 0 )
    {	
	$snr_downstream = $snr_upstream = 'Порт не в онлайне';
	$line_quality = 'Порт не в онлайне';
    }

    return 1;
}
