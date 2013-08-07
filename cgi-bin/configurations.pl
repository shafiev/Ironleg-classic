our $site_name='http://ironleg.azedunet.az';

our $ironleg_port_activator_url = 'http://ironleg.azedunet.az/cgi-bin/port_control.pl?abonnent_id=';
our $ironleg_port_activator_url_key = 'key';


our $time_period_for_report = 7;
our $time_period_before_port_block = 7;


our $mysql_database="radius";
our $mysql_dbserver="x.y.z.w";
our $mysql_username="user";
our $mysql_password="pass";

our $abills_host = 'host';
our $abills_username = 'user';
our $abills_password = 'sectetkey';
our $abills_db = 'abills';
our $abills_address='https://82.194.0.252:9443/admin/index.cgi';
our $ironleg_dbuser = 'TO_OTHER_SYSTEM_FETCHER';
our $ironleg_dbpass = 'pass';

our $currency = 'AZN' ;
our $admin_contact_info='Naim Shafiev 050 633-41-31';

our $path_for_images_of_mrtg = '82.194.0.204';
our $community = 'your_community_snmp';
our $cgi_start_message = "Content-type: text/html\n\n";
our $port_activity_label = 'Ports work log';


our $snmp_port_enable_disable_prefix ='1.3.6.1.2.1.2.2.1.7.'; 
our $snmp_vpi_vci_prefix;
our $snmp_profile_change_prefix = '1.3.6.1.2.1.10.94.1.1.1.1.4.';
our $snmp_timeout = 1;
our $snmp_ies5000_save = '1.3.6.1.4.1.890.1.5.13.5.3.1.0'; # 1 to save 2 to factory reset
our $snmp_ies1000_1248_save = '1.3.6.1.4.1.890.1.5.13.1.3.2.1.0'; # 1 to save 2 to factory reset
our $snmp_snr_upstream ='1.3.6.1.2.1.10.94.1.1.3.1.4.';
our $snmp_snr_downstream = '1.3.6.1.2.1.10.94.1.1.2.1.4.';
our $snmp_ies5000_snr_upstream ='1.3.6.1.2.1.10.94.1.1.2.1.4.';
our $snmp_ies5000_snr_downstream = '1.3.6.1.2.1.10.94.1.1.3.1.4.';

our $snmp_ifInErrors = '1.3.6.1.2.1.2.2.1.14.';
our $snmp_ifOutErrors = '1.3.6.1.2.1.2.2.1.20.';
our $snmp_ifInDiscards = '1.3.6.1.2.1.2.2.1.13.';
our $snmp_ifOutDiscards = '1.3.6.1.2.1.2.2.1.19.';
our $snmp_adslAttainableInRate = '1.3.6.1.2.1.10.94.1.1.2.1.8.';
our $snmp_adslAttainableOutRate = '1.3.6.1.2.1.10.94.1.1.3.1.8.';
our $snmp_adslCurrentInSpeed = '1.3.6.1.2.1.10.94.1.1.4.1.2.';
our $snmp_adslCurrentOutSpeed = '1.3.6.1.2.1.10.94.1.1.5.1.2.';
our $snmp_adslAnnexM_ies5000 = '1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.3.';
our $snmp_adslAnnexM_ies1248 ='1.3.6.1.4.1.890.1.5.13.6.8.2.1.1.3.';
our $snmp_adslAnnexM_ies1000 ='1.3.6.1.4.1.890.1.5.11.11.8.2.1.1.3.';

our $snmp_arp_bulk = '1.3.6.1.2.1.3.1.1.2';

our %adsl_corporate_pvc = {'0/33' => 400 };
our %adsl_private_pvc = {'1/35' => 500 };

our $action_log_file = '/var/www/port_logs/action.log';
our $snmp_default_profile = 'SCHOOL_DEFAULT';
our $port_to_show_count = 24;

our @users_to_port_controlling = ('naim','ATimur','EBalabekov','eseyidov','eseyidova','shahlar','zmammadov','ebadyagin','tabdulazizov','trotkin','sabina','denis','elpaso','MZaur','nnadirov','afarid');

our @private_users_group = ('Azedunet Staff', 'Home User Adsl' , 'Home User 3g');

1;
