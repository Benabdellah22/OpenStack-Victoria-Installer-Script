readonly keystone_config_path="/etc/keystone/"
	readonly keystone_config_file="keystone.conf"

readonly glance_config_path="/etc/glance/"
	readonly glance_api_config_file="glance-api.conf"
	#readonly glance_registry_config_file="glance-registry.conf"

readonly placement_config_path="/etc/placement/"
	readonly placement_config_file="placement.conf"

readonly nova_config_path="/etc/nova/"
	readonly nova_config_file="nova.conf"
	#readonly nova_compute_config_file="nova-compute.conf"

readonly neutron_config_path="/etc/neutron/"
	readonly neutron_config_file="neutron.conf"
	readonly l3_agent_config_file="l3_agent.ini"
	readonly dhcp_agent_config_file="dhcp_agent.ini"
	readonly metadata_agent_config_file="metadata_agent.ini"

readonly neutron_ml2_config_path="/etc/neutron/plugins/ml2/"
	readonly neutron_ml2_config_file="ml2_conf.ini"
	readonly neutron_linuxbridge_config_file="linuxbridge_agent.ini"

readonly cinder_config_path="/etc/cinder/"
	readonly cinder_config_file="cinder.conf"

readonly horizon_local_settings_path="/etc/openstack-dashboard/"
	readonly horizon_local_settings_file="local_settings.py"


readonly lvm_local_settings_path="/etc/lvm/"
	readonly lvm_local_settings_file="lvm.conf"

##############




function backup() {
	mkdir $1
	echo "Copying config files to: "$1
	sleep 3
	cp -f $keystone_config_path$keystone_config_file $1

	cp -f $glance_config_path$glance_api_config_file $1
	cp -f $glance_config_path$glance_registry_config_file $1

	cp -f $placement_config_path$placement_config_file $1


	cp -f $nova_config_path$nova_config_file $1
	cp -f $nova_config_path$nova_compute_config_file $1
	
	cp -f $neutron_config_path$neutron_config_file $1
	cp -f $neutron_config_path$l3_agent_config_file $1
	cp -f $neutron_config_path$dhcp_agent_config_file $1
	cp -f $neutron_config_path$metadata_agent_config_file $1

	cp -f $neutron_ml2_config_path$neutron_ml2_config_file $1
	cp -f $neutron_ml2_config_path$neutron_linuxbridge_config_file $1

	cp -f $cinder_config_path$cinder_config_file $1

	cp -f $horizon_local_settings_path$horizon_local_settings_file $1

	cp -f $lvm_local_settings_path$lvm_local_settings_file $1
}

function restore() {
	echo "Copying config files from: "$1
	sleep 3
	
	cp -f  $1$keystone_config_file $keystone_config_path

	cp -f $1$glance_api_config_file $glance_config_path 
	cp -f $1$glance_registry_config_file  $glance_config_path 

	cp -f $1$placement_config_file $placement_config_path  


	cp -f $1$nova_config_file $nova_config_path  
	cp -f $1$nova_compute_config_file $nova_config_path  
	
	cp -f $1$neutron_config_file $neutron_config_path  
	cp -f $1$l3_agent_config_file $neutron_config_path  
	cp -f $1$dhcp_agent_config_file $neutron_config_path  
	cp -f $1$metadata_agent_config_file $neutron_config_path  

	cp -f $1$neutron_ml2_config_file $neutron_ml2_config_path  
	cp -f $1$neutron_linuxbridge_config_file $neutron_ml2_config_path  

	cp -f $1$cinder_config_file $cinder_config_path  

	cp -f $1$horizon_local_settings_file $horizon_local_settings_path  

	cp -f $1$lvm_local_settings_file $lvm_local_settings_path  
}

if [ $# -ne 2 ]
then
	echo "Correct Syntax: $0 [backup | restore] <directory_name>"
	exit 1
fi

if [ "$1" == "backup" ]
then
	backup $2
elif [ "$1" == "restore" ]
then
	restore $2
else
	echo "Invalid action. Correct Syntax: $0 [backup | restore] <directory_name>"
	exit 1
fi
