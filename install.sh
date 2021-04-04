
function install-common-packages() {
	echo "============= Installing common packages ============="

	echo "... Doing full system update ..."
	sleep 2
	apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y

	apt-get autoremove -y
	apt-get install net-tools -y

	apt-get install python3-openstackclient -y
	echo "... Install usefull packages ..."
	sleep 2
	apt install vim -y
	apt install ifupdown -y

	echo "... Install crudini ..."
	sleep 2
	apt-get install crudini -y
	

	echo "... Install NTP Server ..."
	sleep 2
	apt-get install chrony -y
	service chrony restart
	


	echo "... configure APT for Victoria ..."
	echo "victoria release supported only on ...TODO..."
	sleep 2
	apt-get install software-properties-common -y
	add-apt-repository cloud-archive:victoria -y

	
}








function install-controller-packages() {
	echo "============= Installing controller packages ============="
	echo "... Installing MariaDB ..."
	sleep 1
	apt install mariadb-server python3-pymysql -y
	service mysql restart

	echo "... Installing RabbitMQ ..." 	
	sleep 1
	apt install rabbitmq-server -y

	echo "... Installing Memcached ..." 	
	sleep 1
	apt install memcached python3-memcache -y
	service memcached restart

	echo "... Installing ETCD ..." 	
	sleep 1
	apt install etcd -y
	service etcd restart

	###################################################
	###################################################
	
	echo "... Installing keystone ..." 	
	sleep 1
	apt install keystone -y


	echo "... Installing glance ..." 	
	sleep 1
	apt install glance -y


	echo "... Installing placement ..." 	
	sleep 1
	apt install placement-api -y



	echo "... Installing nova ..." 	
	sleep 1
	apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y


	echo "... Installing neutron ..." 	
	sleep 1
	apt install neutron-server neutron-plugin-ml2 \
	neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
	neutron-metadata-agent -y


	echo "... Installing cinder ..." 	
	sleep 1	
	apt install cinder-api cinder-scheduler -y

	echo "... Installing horizon ..." 	
	sleep 1	
	apt install openstack-dashboard -y



	echo "... Doing autoremove..."
	sleep 1
	apt autoremove -y

}

function install-storage-packages() {
	echo "============= Installing storage packages ============="
	echo "... Installing cinder ..." 	
	sleep 1	

	apt install lvm2 thin-provisioning-tools -y
	apt install cinder-volume -y
}

function install-compute-packages() {
	echo "============= Installing compute packages ============="
	echo "... Installing nova ..." 	
	sleep 1
	apt install nova-compute -y

	echo "... Installing neutron ..." 	
	sleep 1
	apt install neutron-linuxbridge-agent -y
}

########################################################################

function main_install()
{


	echo "1) Install Controller Node Service."
	echo "2) Install Compute Node Service."
	echo "3) Install Block Node Service (Cinder)."
	echo "0) Quit"
	
	read -p "please input one number for install : " install_number

	case ${install_number} in
		1)
			echo "#######################################################"
			echo "############ Install Controller Service ###############"
			echo "#######################################################"
			install-common-packages
			echo "Installing packages for : Controller"
			sleep 5
			install-controller-packages

			main_install
		;;

		2)
			echo "#######################################################"
			echo "############ Install Compute Service ##################"
			echo "#######################################################"

			install-common-packages
			echo "Installing packages for : Compute"
			sleep 5
			install-compute-packages

			main_install
		;;

		3)

			echo "#######################################################"
			echo "############ Install Storage Service ##################"
			echo "#######################################################"

			install-common-packages
			echo "Installing packages for : Block storage"
			sleep 5
			install-storage-packages

			main_install
		;;

		0)
			exit 1
		
		;;
		*)
			echo -e "\033[41;37m please input one number. \033[0m"
			fn_install_openstack
		;;
	esac 


	echo "*********************************************************"
	echo "NEXT STEPS:"
	echo "** Update lib/config-paramters.sh for Interface names"
	echo "** Run the below command on all nodes:"
	echo "            configure.sh <controller_ip_address>"
	echo "*********************************************************"

}




main_install