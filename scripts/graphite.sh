sudo su
set -x
export DEBIAN_FRONTEND=noninteractive

echo "Reading config...." >&2
source /vagrant/setup.rc

##########################################
# INSTALL KEEPALIVED
##########################################
#sudo apt-get install keepalived -y

#echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind
#echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
#sysctl -p

#cp /vagrant/resources/keepalived/keepalived.conf /etc/keepalived/
#sed -i "s/%PRIORITY%/100/g" /etc/keepalived/keepalived.conf

#sed -i "s/%PASSWORD%/$cfg_keepalivepassword/g" /etc/keepalived/keepalived.conf
#sed -i "s/%GRAPHITEHOME%/$cfg_graphitehome/g" /etc/keepalived/keepalived.conf

##########################################
# END INSTALL KEEPALIVED
##########################################

##########################################
# INSTALL HAPROXY
##########################################
apt-get update -y 
apt-get upgrade -y 
apt-get install haproxy -y

cp /vagrant/resources/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg 

sed -i "s/RELAY1/$cfg_ip_relay1/g" /etc/haproxy/haproxy.cfg
sed -i "s/RELAY2/$cfg_ip_relay2/g" /etc/haproxy/haproxy.cfg
sed -i "s/WEB1/$cfg_ip_web1/g" /etc/haproxy/haproxy.cfg
sed -i "s/WEB2/$cfg_ip_web2/g" /etc/haproxy/haproxy.cfg
sed -i "s/SITE1/$cfg_ip_site1/g" /etc/haproxy/haproxy.cfg
sed -i "s/SITE2/$cfg_ip_site2/g" /etc/haproxy/haproxy.cfg

sed -i 's/#$ModLoad imudp/$ModLoad imudp/g' /etc/rsyslog.conf
sed -i 's/#$UDPServerRun 514/$UDPServerRun 514/g' /etc/rsyslog.conf
echo '$UDPServerAddress 127.0.0.1' >> /etc/rsyslog.conf

cat  << 'EOF' > /etc/rsyslog.d/haproxy.conf
if ($programname == 'haproxy') then -/var/log/haproxy.log
EOF

sed -i "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy

##########################################
# END INSTALL HAPROXY
##########################################

############################################
# install statsD 
############################################

sudo aptitude update -y
sudo apt-get install build-essential python-dev libapache2-mod-wsgi libpq-dev python-psycopg2 -y
sudo apt-get install libssl-dev libffi-dev  -y

#pip install cryptography

#pip install --upgrade scrapy
#pip install --upgrade twisted
#pip install --upgrade pyopenssl
#pip install scandir

dpkg -i /vagrant/resources/statsdaemon.deb
#get conf file
cp /vagrant/resources/init/statsdaemon.conf /etc/init

sed -i "s/%GRAPHITEHOME%/$cfg_graphitehome/g" /etc/init/statsdaemon.conf

stop statsdaemon
start statsdaemon

#configure keepalived for this node
service rsyslog restart
#service keepalived stop
#service keepalived start
service haproxy stop
service haproxy start

#build base 
bash /vagrant/scripts/graphite_base.sh
sudo -u graphite python /opt/graphite/bin/carbon-cache.py stop
sudo -u graphite python /opt/graphite/bin/carbon-relay.py stop
service postgresql stop
service apache2 stop

#install memcached while there
apt-get install memcached

echo "==========================================="
echo " carbon setting "
echo "==========================================="
#install relay stuff
sudo cp -Rf /vagrant/resources/carbon/storage-schemas.conf /etc/carbon/storage-schemas.conf
cp /vagrant/resources/carbon/carbon.conf /etc/carbon/carbon.conf
sed -i "s/CARBON1/$cfg_ip_carbon1/g" /etc/carbon/carbon.conf
sed -i "s/CARBON2/$cfg_ip_carbon2/g" /etc/carbon/carbon.conf
sed -i "s/SITE1/$cfg_ip_site1/g" /etc/carbon/carbon.conf
sed -i "s/SITE2/$cfg_ip_site2/g" /etc/carbon/carbon.conf

sudo graphite-manage syncdb --noinput

sudo sed -i "s/CARBON_CACHE_ENABLED=false/CARBON_CACHE_ENABLED=true/g" /etc/default/graphite-carbon
sudo sed -i "s/ENABLE_LOGROTATION = False/ENABLE_LOGROTATION = True/g" /etc/carbon/carbon.conf

#PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py syncdb --settings=graphite.settings --noinput
#PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py collectstatic --noinput --settings=graphite.settings
#PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py shell --settings=graphite.settings

cp /vagrant/resources/init.d/* /etc/init.d/
chmod 777 /etc/init.d/carbon-*

/etc/init.d/carbon-storage stop
/etc/init.d/carbon-storage start
/etc/init.d/carbon-relay stop
/etc/init.d/carbon-relay start

echo "CARBONLINK_HOSTS = [\"127.0.0.1:7102:1\", \"127.0.0.1:7202:2\"]" >> /etc/graphite/local_settings.py
#end carbon

#install website
easy_install python-memcached
#modify webapp a bit
echo "CLUSTER_SERVERS = [\"$cfg_ip_carbon1:8080\", \"$cfg_ip_carbon2:8080\"]" >> /etc/graphite/local_settings.py
echo "MEMCACHE_HOSTS = [\"$cfg_ip_memcache1:11211\", \"$cfg_ip_memcache2:11211\"]" >> /etc/graphite/local_settings.py
#end website

service postgresql start
service apache2 start

#apply firewall rules
mkdir -p /etc/iptables
cp /vagrant/resources/iptables/rules /etc/iptables/rules

sed -i "s/^iptables-restore//g" /etc/network/if-up.d/iptables
echo "iptables-restore < /etc/iptables/rules" >> /etc/network/if-up.d/iptables
iptables-restore < /etc/iptables/rules

#install failtoban
apt-get install fail2ban sendmail -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i "s/^destemail.*/destemail = doohee323@gmail.com/g" /etc/fail2ban/jail.local
sed -i "s/^action = %(action_)s/action = %(action_mwl)s/g" /etc/fail2ban/jail.local
service fail2ban stop
service fail2ban start
service rsyslog restart

#install ganglia
#using this repo to install ganglia 3.4 as it allows for host name overwrites
#add-apt-repository ppa:rufustfirefly/ganglia
# Update and begin installing some utility tools
#apt-get -y update
apt-get install ganglia-monitor -y

cp /vagrant/resources/ganglia/gmond.conf /etc/ganglia/gmond.conf
sed -i "s/MONITORNODE/$cfg_ganglia_server/g" /etc/ganglia/gmond.conf
sed -i "s/THISNODEID/$cfg_ganglia_nodes_prefix-graphite/g" /etc/ganglia/gmond.conf

sed -i "s/THISNODEID/graphite1/g" /etc/ganglia/gmond.conf
/etc/init.d/ganglia-monitor restart

echo "done!"
