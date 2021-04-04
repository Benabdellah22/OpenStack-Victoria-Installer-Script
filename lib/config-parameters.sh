controller_hostname="controller"

### Start - interface related settings
readonly ext_interface="enp0s3"
readonly provider_interface="enp0s8"
readonly mgmt_interface="enp0s9"
### End - interface related settings

###############

readonly mysql_user="root"
readonly mysql_password="pirate"

readonly rabbitmq_user="openstack"
readonly rabbitmq_password="RABBIT_PASS"


readonly admin_tenant_password="ADMIN_PASS"
readonly keystone_db_password="KEYSTONE_DBPASS"

readonly glance_password="GLANCE_PASS"
readonly glance_db_password="GLANCE_DBPASS"

readonly placement_password="PLACEMENT_PASS"
readonly placement_db_password="PLACEMENT_DBPASS"

readonly nova_password="NOVA_PASS"
readonly nova_db_password="NOVA_DBPASS"

readonly neutron_password="NEUTRON_PASS"
readonly neutron_db_password="NEUTRON_DBPASS"

readonly cinder_password="CINDER_PASS"
readonly cinder_db_password="CINDER_DBPASS"


function print_keystone_service_list() {
	echo_and_sleep "About to print Keystone Service List" 2
	openstack service list --long
	echo_and_sleep "About to print OpenStack Catalog List" 2
	openstack catalog list
	echo_and_sleep "Catalog list printed" 2
}


function echo_and_sleep() {
	if [ -z "$2" ]
		then
			sleep_time=3
		else
			sleep_time=$2
	fi

	if [ -z "$1" ]
		then
			echo_string="About to sleep for "$sleep_time" seconds..."
		else
			echo_string=$1
	fi
	echo "$echo_string and sleeping for "$sleep_time" seconds..."
	sleep $sleep_time
}

function create-user-service() {
	echo "Called create-user-service with paramters: $@"
	sleep 3
	openstack user create --domain default --password $2 $1
	echo_and_sleep "Created User $1" 2
	openstack role add --project service --user $1 admin
	echo_and_sleep "Created Role $1" 2
	openstack service create --name $3 --description $4 $5
	echo_and_sleep "Created Service $4" 2
}

function create-api-endpoints() {
	echo "Called create-api-endpoints with parameters: $@"
	sleep 5
	openstack endpoint create --region RegionOne $1 public $2
	echo_and_sleep "Created public endpoint" 2
	openstack endpoint create --region RegionOne $1 internal $2
	echo_and_sleep "Created internal endpoint" 2
	openstack endpoint create --region RegionOne $1 admin $2
	echo_and_sleep "Created admin endpoint" 2
}


function configure-keystone-authentication() {
	echo "Called configure-keystone-authentication with paramters: $@"
	sleep 3
	crudini --set $1 keystone_authtoken www_authenticate_uri http://$2:5000
	crudini --set $1 keystone_authtoken auth_url http://$2:5000
	crudini --set $1 keystone_authtoken memcached_servers $2:11211
	crudini --set $1 keystone_authtoken auth_type password
	crudini --set $1 keystone_authtoken project_domain_name default
	crudini --set $1 keystone_authtoken user_domain_name default
	crudini --set $1 keystone_authtoken project_name service
	crudini --set $1 keystone_authtoken username $3
	crudini --set $1 keystone_authtoken password $4
}


function get-ip-address() {
        ip_address_val=''
     
        ip_address_val=`ifconfig $1 | grep 'inet ' | cut -d' ' -f10 | awk '{ print $1}'`       

        echo $ip_address_val
}

