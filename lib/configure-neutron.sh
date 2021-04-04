echo "Running: $0 $@"
source $(dirname $0)/config-parameters.sh

if [ "$1" != "controller" ] && [ "$1" != "compute" ]
	then
		echo "Correct Syntax: $0 [ controller | compute ] <controller-host-name> <neutron-password> <rabbitmq-password> <neutron-db-password> <mysql-username> <mysql-password>"
		exit 1;
fi

if [ "$1" == "controller" ] && [ $# -ne 7 ]
	then
		echo "Correct Syntax: $0 controller <controller-host-name> <neutron-password> <rabbitmq-password> <neutron-db-password> <mysql-username> <mysql-password>"
		exit 1;
fi
		
if [ "$1" == "compute" ] && [ $# -ne 4 ]
	then
		echo "Correct Syntax: $0 compute <controller-host-name> <neutron-password> <rabbitmq-password>"
		exit 1;
fi
		
source $(dirname $0)/admin_openrc.sh

if [ "$1" == "controller" ]
	then
		echo "Configuring MySQL for Neutron API..."
		mysql_command="CREATE DATABASE IF NOT EXISTS neutron; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$5'; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$5';"
		echo "MySQL Command is:: "$mysql_command
		mysql -u "$6" -p"$7" -e "$mysql_command"
				

		create-user-service neutron $3 neutron OpenStackNetwork network		
		create-api-endpoints network http://$2:9696
		echo_and_sleep "Created Endpoint for Neutron" 2

		crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$5@$2/neutron
		echo_and_sleep "Configured Neutron DB Connection" 2

fi

echo_and_sleep "Updating Neutron Configuration File" 1
echo_and_sleep "RabbitMQ config changed for Neutron" 1

crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$4@$2

crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

configure-keystone-authentication /etc/neutron/neutron.conf $2 neutron $3

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

crudini --set /etc/nova/nova.conf neutron auth_url http://$2:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $3

#Networking Option 2: Self-service networks:
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:enp0s8

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
##

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


if [ "$1" == "controller" ]
	then
	crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
	crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
	crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
	

	crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
	crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

	crudini --set /etc/neutron/neutron.conf nova auth_url http://$2:5000
	crudini --set /etc/neutron/neutron.conf nova auth_type password
	crudini --set /etc/neutron/neutron.conf nova project_domain_name default
	crudini --set /etc/neutron/neutron.conf nova user_domain_name default
	crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
	crudini --set /etc/neutron/neutron.conf nova project_name service
	crudini --set /etc/neutron/neutron.conf nova username nova
	##TODO
	crudini --set /etc/neutron/neutron.conf nova password NOVA_PASS
	###################################################################
	mgmt_interface_ip=$(get-ip-address $mgmt_interface)
	echo "Mgmt Interface IP Address: $mgmt_interface_ip"
	sleep 1	

	#Configure the Modular Layer 2 (ML2) plug-in
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers "flat,vlan,vxlan"
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers "linuxbridge,l2population"
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

	#Configure the Linux bridge agent
	crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $mgmt_interface_ip


	#Configure the layer-3 agent
	crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

	#Configure the DHCP agent
	crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
	crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
	crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true
	#=================================================
	#Configure the metadata agent
	crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
	crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret METADATA_SECRET

	#Configure the Compute service to use the Networking service


	crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
	crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret METADATA_SECRET

elif [ "$1" == "compute" ]
	then
	mgmt_interface_ip=$(get-ip-address $mgmt_interface)
	echo "Mgmt Interface IP Address: $mgmt_interface_ip"
	sleep 1	
	crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $mgmt_interface_ip
fi




echo_and_sleep "Updated Neutron Configuration File" 2

if [ "$1" == "controller" ]
	then
		echo_and_sleep "Populate Neutron Database" 1
		neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head

		echo_and_sleep "Restarting Neutron Service" 2
		######
		service nova-api restart
		service neutron-server restart
		service neutron-linuxbridge-agent restart
		service neutron-dhcp-agent restart
		service neutron-metadata-agent restart
		service neutron-l3-agent restart

elif [ "$1" == "compute" ]
	then
		echo "Restarting Neutron Service"	
		service nova-compute restart
		service neutron-linuxbridge-agent restart
fi

#echo_and_sleep "Removing Nova MySQL-Lite Database" 2
#rm -f /var/lib/nova/nova.sqlite

if [ "$1" == "controller" ]
	then
		echo "done"
		#print_keystone_service_list		
		#nova service-list
		#echo_and_sleep "Network agent list" 2
		#openstack network agent list

		#echo_and_sleep "extension list --network" 2
		#openstack extension list --network
fi

