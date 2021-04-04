echo "Running: $0 $@"
source $(dirname $0)/config-parameters.sh

if [ $# -lt 6 ]
	then
		echo "Correct Syntax: $0 <placement-db-password> <mysql-username> <mysql-password> <controller-host-name> <admin-tenant-password> <placement-password>"
		exit 1
fi


echo "Configuring MySQL for Placement..."
mysql_command="CREATE DATABASE IF NOT EXISTS placement; GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '$1'; GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '$1';"
echo "MySQL Command is:: "$mysql_command
mysql -u "$2" -p"$3" -e "$mysql_command"



source $(dirname $0)/admin_openrc.sh
echo_and_sleep "Called Source Admin OpenRC"


create-user-service placement $6 placement PlacementAPI placement

create-api-endpoints placement http://$4:8778
echo_and_sleep "Added Placement Service Endpoint"

#######################

echo "Configuring Placement..."


crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:$1@$4/placement

crudini --set /etc/placement/placement.conf api auth_strategy keystone

configure-keystone-authentication /etc/placement/placement.conf $4 placement $6


echo_and_sleep "About to populate Placement Service Database" 
placement-manage db sync

echo_and_sleep "Restarting Placement Service..." 3
service apache2 restart


print_keystone_service_list
