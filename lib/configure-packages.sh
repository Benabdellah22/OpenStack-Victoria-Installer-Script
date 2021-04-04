source $(dirname $0)/config-parameters.sh

function configure-mysql-controller() {
	echo_and_sleep "About to configure MySQL on Controller"	
	if [ -d "/etc/mysql/mariadb.conf.d/" ]
	then
		echo_and_sleep "Maria DB Conf file found" 2

		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld bind-address $1
		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld default-storage-engine innodb
		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld innodb_file_per_table on
		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld max_connections 4096
		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld collation-server utf8_general_ci
		crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld character-set-server utf8
	else 
		echo_and_sleep "Maria DB Conf File Not Found" 2
		echo "TODO"

	fi

	echo_and_sleep "Updated other MySQL Parameters. About to restart and secure MySQL" 2
	service mysql restart
}


if [ "$1" == "compute" ]
	then
		echo_and_sleep "About to configure Compute" 3
		#### NTP ####
		sed -e '/pool/ s/^#*/#/g' -i /etc/chrony/chrony.conf
		sed -e '$ a server controller iburst' -i /etc/chrony/chrony.conf
		service chrony restart

		#############

		echo_and_sleep "About to configure Nova for Compute" 3
		bash $(dirname $0)/configure-nova.sh compute $controller_hostname $nova_password $rabbitmq_password
		
		echo_and_sleep "About to configure Neutron for Compute" 3
		bash $(dirname $0)/configure-neutron.sh compute $controller_hostname $neutron_password $rabbitmq_password 


elif [ "$1" == "controller" ] 
	then
		echo_and_sleep "About to configure controller" 3

		if [ $# -ne 2 ]
		then
			echo "Correct syntax: $0 controller <controller_ip_address>"
			exit 1;
		fi
		###### N T P ######
		## TODO hard coded
		#crudini --set /etc/chrony/chrony.conf '' allow 10.0.0.0/24
		sed -e '$ a allow 10.0.0.0/24' -i /etc/chrony/chrony.conf
		service chrony restart

		###### MYSQL ######		
		configure-mysql-controller $2
		bash $(dirname $0)/mysql-secure-installation.sh $mysql_user $mysql_password
		echo_and_sleep "Completed MySQL Config and Secure Installation" 2

		###### Rabbitmq ######
		echo_and_sleep "Rabbit MQ: Updating password: $rabbitmq_password"
		rabbitmqctl add_user $rabbitmq_user $rabbitmq_password
		echo_and_sleep "Rabbit MQ: User Added. About to set Permissions"
		rabbitmqctl set_permissions $rabbitmq_user ".*" ".*" ".*"
		echo_and_sleep "Configured Permissions in Rabbit MQ"
		service rabbitmq-server restart
		
		###### memcached ######
		echo_and_sleep "Configuring memcached"
		sed -i "s/127.0.0.1/$2/g" /etc/memcached.conf
		service memcached restart

		###### etcd ######		
		echo_and_sleep "Configuring etcd"
		
		crudini --set /etc/default/etcd '' ETCD_NAME '"controller"'
		crudini --set /etc/default/etcd '' ETCD_DATA_DIR '"/var/lib/etcd"'
		crudini --set /etc/default/etcd '' ETCD_INITIAL_CLUSTER_STATE '"new"'
		crudini --set /etc/default/etcd '' ETCD_INITIAL_CLUSTER_TOKEN '"etcd-cluster-01"'
		crudini --set /etc/default/etcd '' ETCD_INITIAL_CLUSTER '"controller=http://'$2':2380"'
		crudini --set /etc/default/etcd '' ETCD_INITIAL_ADVERTISE_PEER_URLS '"http://'$2':2380"'
		crudini --set /etc/default/etcd '' ETCD_ADVERTISE_CLIENT_URLS '"http://'$2':2379"'
		crudini --set /etc/default/etcd '' ETCD_LISTEN_PEER_URLS '"http://0.0.0.0:2380"'
		crudini --set /etc/default/etcd '' ETCD_LISTEN_CLIENT_URLS '"http://'$2':2379"'

		service etcd restart

		#########################################################
		echo_and_sleep "About to setup KeyStone..."
		bash $(dirname $0)/configure-keystone.sh $keystone_db_password $mysql_user $mysql_password $controller_hostname $admin_tenant_password
		source $(dirname $0)/admin_openrc.sh

		echo_and_sleep "About to setup Glance..."
		bash $(dirname $0)/configure-glance.sh $glance_db_password $mysql_user $mysql_password $controller_hostname $admin_tenant_password $glance_password


		echo_and_sleep "About to setup Placement..."
		bash $(dirname $0)/configure-placement.sh $placement_db_password $mysql_user $mysql_password $controller_hostname $admin_tenant_password $placement_password

		echo_and_sleep "About to setup NOVA..."
		bash $(dirname $0)/configure-nova.sh controller $controller_hostname $nova_password $rabbitmq_password $nova_db_password $mysql_user $mysql_password 

		echo_and_sleep "About to setup Neutron..."
		bash $(dirname $0)/configure-neutron.sh controller $controller_hostname $neutron_password $rabbitmq_password $neutron_db_password $mysql_user $mysql_password 

		echo_and_sleep "About to setup Cinder"
		bash $(dirname $0)/configure-cinder.sh controller $controller_hostname $cinder_password $rabbitmq_password $cinder_db_password $mysql_user $mysql_password 


		echo_and_sleep "About to setup Horizon-Dashboard"
		bash $(dirname $0)/configure-horizon.sh $controller_hostname



elif [ "$1" == "storage" ]
	then
		echo_and_sleep "About to configure Storage Node"

		#### NTP ####
		sed -e '/pool/ s/^#*/#/g' -i /etc/chrony/chrony.conf
		sed -e '$ a server controller iburst' -i /etc/chrony/chrony.conf
		service chrony restart
		#############
		echo_and_sleep "About to configure Cinder for storage" 3
		bash $(dirname $0)/configure-cinder.sh storage $controller_hostname $cinder_password $rabbitmq_password
		

else
        echo "Correct syntax 1: $0 controller <controller_ip_address>"
        echo "Correct syntax 2: $0 [ compute | storage ]"
        exit 1;

fi