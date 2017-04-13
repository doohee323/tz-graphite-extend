sudo su
set -x
export DEBIAN_FRONTEND=noninteractive

echo "Reading config...." >&2
source /vagrant/setup.rc

##########################################
#
# INSTALL KEEPALIVED
#
##########################################
#sudo apt-get install keepalived -y

#echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind
#echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
#sysctl -p

#cp /vagrant/etc/keepalived/keepalived.conf /etc/keepalived/
#sed -i "s/%PRIORITY%/100/g" /etc/keepalived/keepalived.conf

#sed -i "s/%PASSWORD%/$cfg_keepalivepassword/g" /etc/keepalived/keepalived.conf
#sed -i "s/%GRAPHITEHOME%/$cfg_graphitehome/g" /etc/keepalived/keepalived.conf

##########################################
#
# END INSTALL KEEPALIVED
#
##########################################

##########################################
#
# INSTALL HAPROXY
#
##########################################
apt-get -y update
apt-get -y upgrade
apt-get install haproxy -y

#copy config

cp /vagrant/etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg 

sed -i "s/RELAY1/$cfg_ip_relay1/g" /etc/haproxy/haproxy.cfg
sed -i "s/RELAY2/$cfg_ip_relay2/g" /etc/haproxy/haproxy.cfg
sed -i "s/WEB1/$cfg_ip_web1/g" /etc/haproxy/haproxy.cfg
sed -i "s/WEB2/$cfg_ip_web2/g" /etc/haproxy/haproxy.cfg
sed -i "s/SITE1/$cfg_ip_site1/g" /etc/haproxy/haproxy.cfg
sed -i "s/SITE2/$cfg_ip_site2/g" /etc/haproxy/haproxy.cfg

sed -i 's/#$ModLoad imudp/$ModLoad imudp/g' /etc/rsyslog.conf
sed -i 's/#$UDPServerAddress 127.0.0.1/$UDPServerAddress 127.0.0.1/g' /etc/rsyslog.conf
sed -i 's/#$UDPServerRun 514/$UDPServerRun 514/g' /etc/rsyslog.conf

cat  << 'EOF' > /etc/rsyslog.d/haproxy.conf
if ($programname == 'haproxy') then -/var/log/haproxy.log
EOF

sed -i "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy

##########################################
#
# END INSTALL HAPROXY
#
##########################################

############################################
#
# install statsD 
#
############################################

dpkg -i /vagrant/statsdaemon.deb
#get conf file
cp /vagrant/etc/init/statsdaemon.conf /etc/init

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
source /vagrant/scripts/graphite_base.sh
sudo -u graphite python /opt/graphite/bin/carbon-cache.py stop
sudo -u graphite python /opt/graphite/bin/carbon-relay.py stop
service postgresql stop
service apache2 stop

#install memcached while there
apt-get install memcached

#install relay stuff
cp /vagrant/opt/graphite/conf/carbon.conf /opt/graphite/conf/carbon.conf
sed -i "s/CARBON1/$cfg_ip_carbon1/g" /opt/graphite/conf/carbon.conf
sed -i "s/CARBON2/$cfg_ip_carbon2/g" /opt/graphite/conf/carbon.conf
sed -i "s/SITE1/$cfg_ip_site1/g" /opt/graphite/conf/carbon.conf
sed -i "s/SITE2/$cfg_ip_site2/g" /opt/graphite/conf/carbon.conf

cp /vagrant/etc/init.d/* /etc/init.d/
chmod 777 /etc/init.d/carbon-*

/etc/init.d/carbon-storage stop
/etc/init.d/carbon-storage start
/etc/init.d/carbon-relay stop
/etc/init.d/carbon-relay start

echo "CARBONLINK_HOSTS = [\"127.0.0.1:7102:1\", \"127.0.0.1:7202:2\"]" >> /opt/graphite/webapp/graphite/local_settings.py
#end carbon

#install website
easy_install python-memcached
#modify webapp a bit
echo "CLUSTER_SERVERS = [\"$cfg_ip_carbon1:80\", \"$cfg_ip_carbon2:80\"]" >> /opt/graphite/webapp/graphite/local_settings.py
echo "MEMCACHE_HOSTS = [\"$cfg_ip_memcache1:11211\", \"$cfg_ip_memcache2:11211\"]" >> /opt/graphite/webapp/graphite/local_settings.py
#end website

#install ganglia
#using this repo to install ganglia 3.4 as it allows for host name overwrites
#add-apt-repository ppa:rufustfirefly/ganglia
# Update and begin installing some utility tools
apt-get -y update
apt-get install ganglia-monitor -y

cp /vagrant/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
sed -i "s/MONITORNODE/$cfg_ganglia_server/g" /etc/ganglia/gmond.conf
sed -i "s/THISNODEID/graphite1/g" /etc/ganglia/gmond.conf
/etc/init.d/ganglia-monitor restart

service postgresql start
service apache2 start
#service apache2 restart

#apply firewall rules
mkdir -p /etc/iptables
cp /vagrant/etc/iptables/rules /etc/iptables/rules

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
echo "done!"
