use Net::SNMP;
use warnings;
use Data::Dumper;
use SNMP::Info::Layer2::ZyXEL_DSLAM ;
use SNMP::Info::Bridge;

require 'configurations.pl';

my $zyxel = new SNMP::Info(
                         AutoSpecify => 1,
                         Debug       => 1,
                         DestHost    => '10.17.33.253',
                         Community   => $community,
                         Version     => 1
                       )
    or die "Can't connect to DestHost.\n";
 

#print Dumper( $zyxel ->fw_mac());

print Dumper($interfaces);

my $interfaces = $zyxel->interfaces();
my $fw_mac     = $zyxel->fw_mac();
my $fw_port    = $zyxel->fw_port();
my $bp_index   = $zyxel->bp_index();
 
foreach my $fw_index (keys %$fw_mac){
    my $mac   = $fw_mac->{$fw_index};
    my $bp_id = $fw_port->{$fw_index};
    my $iid   = $bp_index->{$bp_id};
    my $port  = $interfaces->{$iid};
 
    print "Port:$port forwarding to $mac\n";
}
