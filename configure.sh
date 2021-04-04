dir_path=$(dirname $0)
node_type=`bash $dir_path/util/detect-nodetype.sh`
source $dir_path/lib/config-parameters.sh


echo "Node Type detected as: "$node_type
echo "External interface: "$ext_interface
echo "Provider interface: "$provider_interface
echo "Management interface: "$mgmt_interface
echo "Controller Host Name: "$controller_hostname



bash $dir_path/util/backup-restore-config-files.sh backup $dir_path/config_file_backup/
echo "Backed up Config files"
sleep 5

############################################
if [ $# -ne 1 ]
then
       	echo "Correct Syntax: $0 <controller_ip_address>"
	exit 1
fi

############################################
###TODO : configure /etc/hosts
###TODO :           /etc/network/interfaces
###TODO :           /etc/hostname


############################################

if [ "$node_type" == "controller" ]
	then
		echo "Configuring packages for controller node"
		sleep 5
		bash $dir_path/lib/configure-packages.sh controller $1

elif [ "$node_type" == "compute" ] 
	then
		echo "Configuring packages for compute node "
		sleep 5
		bash $dir_path/lib/configure-packages.sh compute

elif [ "$node_type" == "storage" ]
	then
		echo "Configuring packages for storage node"
		sleep 5
		bash $dir_path/lib/configure-packages.sh storage 
else
	echo "Unsupported Node Type for $0: $node_type"
	exit 1;
fi


if [ "$node_type" == "controller" ]
	then
		echo "************************************"
		echo "** Execute post-config-actions.sh **"
		echo "************************************"
fi