
#!/usr/bin/env bash

echo "Making Base...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

# Update and begin installing some utility tools
apt-get -y update
apt-get -y upgrade

apt-get install python-software-properties libtool autoconf automake uuid-dev build-essential wget curl git monit -y

echo "Base done!"

sudo rm -rf /var/lib/apt/lists/*

apt-get install --assume-yes apache2 apache2-mpm-worker apache2-utils python-pip libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libffi-dev python-dev python3-minimal libapache2-mod-wsgi libaprutil1-ldap memcached python-cairo-dev python-django python-ldap python-memcache python-pysqlite2 sqlite3 sudo python-rrd python-setuptools
apt-get install postgresql postgresql-client -y 

#pip install virtualenv

#virtualenv /opt/graphite
#source /opt/graphite/bin/activate

#carbon
git clone https://github.com/graphite-project/carbon.git
cd /home/vagrant/carbon
python setup.py install
cd /home/vagrant
#rm -rf carbon

#whisper
git clone https://github.com/graphite-project/whisper.git
cd /home/vagrant/whisper
python setup.py install
cd /home/vagrant
#rm -rf whisper

#ceres although we dont use it
git clone https://github.com/graphite-project/ceres.git
cd /home/vagrant/ceres
python setup.py install
cd /home/vagrant
#rm -rf ceres

# Get latest pip
pip install --upgrade pip 
pip install requests[security]

#get latest snapshots
git clone https://github.com/graphite-project/graphite-web.git
cd /home/vagrant/graphite-web
python setup.py install

# Install carbon and graphite deps
sudo rm -Rf /tmp/graphite_reqs.txt 
cat >> /tmp/graphite_reqs.txt << EOF
Django==1.7
python-memcached==1.47
txAMQP==0.4
simplejson==2.1.6
django-tagging==0.3.6
gunicorn
pytz
pyparsing==1.5.7
cairocffi
whitenoise
tzlocal
EOF

sudo pip install -r /tmp/graphite_reqs.txt

python check-dependencies.py

sudo cp /vagrant/resources/etc/apache2/sites-enabled/graphite.wsgi /opt/graphite/conf
rm -Rf /etc/apache2/sites-enabled/*
sudo cp /vagrant/resources/etc/apache2/sites-enabled/graphite.conf /etc/apache2/sites-enabled

#rm -rf graphite-web

cd /opt/graphite/webapp/graphite
sudo cp local_settings.py.example local_settings.py

sudo sed -i "s/SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = 'a_salty_string'/g" /opt/graphite/webapp/graphite/settings.py
sudo sed -i "s/LOG_DIR = STORAGE_DIR \+ 'log\/webapp\/'/LOG_DIR = '\/var\/log\/apache2\/'/g" /opt/graphite/webapp/graphite/settings.py

sudo rm -Rf /opt/graphite/conf/examples
sudo mkdir /opt/graphite/conf/examples
sudo mv /opt/graphite/conf/*.example /opt/graphite/conf/examples/

sudo cp /opt/graphite/conf/examples/carbon.conf.example /opt/graphite/conf/carbon.conf
#cp storage-schemas.conf.example storage-schemas.conf

cat  << 'EOF' > /opt/graphite/conf/storage-schemas.conf

[default_1min_for_1day]
pattern = .*
retentions = 1m:7d

[production_staging]
pattern = ^(PRODUCTION|STAGING).*
retentions = 1m:365d

EOF

useradd -p `openssl passwd password` graphite
chown -R graphite:graphite /opt/graphite

#enable headers
a2enmod headers

cat << 'EOF'  >> /etc/apache2/apache2.conf
Header set Access-Control-Allow-Origin "*"
ServerName localhost
EOF

service apache2 restart

PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py syncdb --settings=graphite.settings --noinput
PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py collectstatic --noinput --settings=graphite.settings
#PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py shell --settings=graphite.settings

chmod 777 -R /opt/graphite/storage

#sudo -u graphite python /opt/graphite/bin/carbon-cache.py start 

#using this repo to install ganglia 3.4 as it allows for host name overwrites
add-apt-repository ppa:rufustfirefly/ganglia
# Update and begin installing some utility tools
apt-get -y update
apt-get install ganglia-monitor -y

cp /vagrant/resources/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
sed -i "s/MONITORNODE/$cfg_ganglia_server/g" /etc/ganglia/gmond.conf
sed -i "s/THISNODEID/$cfg_ganglia_nodes_prefix-graphite/g" /etc/ganglia/gmond.conf
/etc/init.d/ganglia-monitor restart

echo "done!"
