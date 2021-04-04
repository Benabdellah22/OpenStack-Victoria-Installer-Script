echo "Running: $0 $@"
source $(dirname $0)/config-parameters.sh
if [ $# -lt 1 ]
        then
                echo "Correct Syntax: $0 <cotroller-host-name>"
                exit 1
fi

#echo_and_sleep "Copying local_settings.py to /etc/openstack-dashboard" 2
#cp $(dirname $0)/local_settings.py /etc/openstack-dashboard/
#echo_and_sleep "Copied local_settings.py to /etc/openstack-dashboard" 2
	
crudini --set /etc/openstack-dashboard/local_settings.py '' SESSION_ENGINE "'django.contrib.sessions.backends.cache'"

sed -e "/^OPENSTACK_HOST =.*$/s/^.*$/OPENSTACK_HOST = \""$1"\"/" -i /etc/openstack-dashboard/local_settings.py

##TODO
sed -e "/'LOCATION'.*$/s/^.*$/'LOCATION' : \'"$1:11211"\'/" -i /etc/openstack-dashboard/local_settings.py

grep "OPENSTACK_HOST" /etc/openstack-dashboard/local_settings.py

grep "LOCATION" /etc/openstack-dashboard/local_settings.py

echo_and_sleep "Restarting apache2" 1
#service apache2 reload
systemctl reload apache2.service
echo_and_sleep "Restarted apache2" 1
