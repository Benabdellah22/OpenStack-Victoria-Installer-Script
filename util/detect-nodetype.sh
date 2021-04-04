

function detect_nodetype()
{

	node_type="Unknown"
	nova_api_installed=false
	nova_compute_installed=false
	cinder_volume_installed=false
	
	dpkg --list | grep nova-api | grep -q ii
	if [ $? -eq 0 ]
	then
		nova_api_installed=true
	fi

	dpkg --list | grep nova-compute | grep -q ii
	if [ $? -eq 0 ]
	then
		nova_compute_installed=true
	fi

	dpkg --list | grep cinder-volume | grep -q ii
	if [ $? -eq 0 ]
	then
		cinder_volume_installed=true
	fi



	if [ $nova_api_installed == "true" ]
	then
		node_type="controller"

	elif [ $nova_compute_installed == "true" ]
	then
		node_type="compute"

	elif [ $cinder_volume_installed == "true" ]
	then
		node_type="storage"

	fi

	echo $node_type
	

}

detect_nodetype