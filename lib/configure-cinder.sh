echo "Running: $0 $@"
source $(dirname $0)/config-parameters.sh

if [ "$1" != "controller" ] && [ "$1" != "storage" ]
	then
		echo "Correct Syntax: $0 [ controller | storage ] <controller-host-name> <cinder-password> <rabbitmq-password> <cinder-db-password> <mysql-username> <mysql-password>"
		exit 1;
fi

if [ "$1" == "controller" ] && [ $# -ne 7 ]
	then
		echo "Correct Syntax: $0 controller <controller-host-name> <cinder-password> <rabbitmq-password> <cinder-db-password> <mysql-username> <mysql-password>"
		exit 1;
fi
		
if [ "$1" == "storage" ] && [ $# -ne 4 ]
	then
		echo "Correct Syntax: $0 storage <controller-host-name> <cinder-password> <rabbitmq-password>"
		exit 1;
fi
		
source $(dirname $0)/admin_openrc.sh
#############################################
if [ "$1" == "controller" ]
	then
		echo "Configuring MySQL for Cinder ..."
		mysql_command="CREATE DATABASE IF NOT EXISTS cinder; GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$5'; GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$5';"
		echo "MySQL Command is:: "$mysql_command
		mysql -u "$6" -p"$7" -e "$mysql_command"
		
		create-user-service cinder $3 cinderv2 OpenStackBlockStorage volumev2		
		openstack service create --name cinderv3 --description OpenStackBlockStorage volumev3
		
		create-api-endpoints volumev2 http://$2:8776/v2/%\(project_id\)s
		create-api-endpoints volumev3 http://$2:8776/v3/%\(project_id\)s
		echo_and_sleep "Created Endpoint for cinder" 2

		echo_and_sleep "Configured Cinder DB Connection" 2

fi

echo_and_sleep "Updating Cinder Configuration File" 1


crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:RABBIT_PASS@controller

crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://controller:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password CINDER_PASS

crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp



if [ "$1" == "controller" ]
	then
	mgmt_interface_ip=$(get-ip-address $mgmt_interface)
	echo "Mgmt Interface IP Address: $mgmt_interface_ip"
	sleep 2	
	crudini --set /etc/cinder/cinder.conf DEFAULT my_ip $mgmt_interface_ip
	crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne
elif [ "$1" == "storage" ]
	then	
	mgmt_interface_ip=$(get-ip-address $mgmt_interface)
	echo "Mgmt Interface IP Address: $mgmt_interface_ip"
	sleep 2	
	crudini --set /etc/cinder/cinder.conf DEFAULT my_ip $mgmt_interface_ip
	###
	crudini --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
	crudini --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes
	crudini --set /etc/cinder/cinder.conf lvm target_protocol iscsi
	crudini --set /etc/cinder/cinder.conf lvm target_helper tgtadm
	crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
	crudini --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://controller:9292


fi


echo_and_sleep "Updated Cinder Configuration File" 2

if [ "$1" == "controller" ]
	then
		echo_and_sleep "Populate Cinder Database" 1
		cinder-manage db sync

		echo_and_sleep "Restarting Cinder Service" 2
		service nova-api restart
		service cinder-scheduler restart
		service apache2 restart
elif [ "$1" == "storage" ]
	then
		echo "Restarting Cinder Service"
		service tgt restart
		service cinder-volume restart
fi

#echo_and_sleep "Removing Nova MySQL-Lite Database" 2
#rm -f /var/lib/nova/nova.sqlite

if [ "$1" == "controller" ]
	then
		echo "done"
		#print_keystone_service_list		
		#echo_and_sleep "Listing Cinder volume list" 1
		#openstack volume service list
fi