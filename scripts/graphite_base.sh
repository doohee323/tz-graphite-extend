
#!/usr/bin/env bash

echo "Making Base...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive
# Update and begin installing some utility tools
apt-get -y update
apt-get -y upgrade

apt-get install python-software-properties libtool autoconf automake uuid-dev build-essential wget curl git monit -y

echo "Base done!"

echo "Reading config...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
sudo apt-get autoremove -y
apt-get install --assume-yes apache2 apache2-mpm-worker apache2-utils python-pip libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libffi-dev python-dev python3-minimal libapache2-mod-wsgi libaprutil1-ldap memcached python-cairo-dev python-django python-ldap python-memcache python-pysqlite2 sqlite3 python-rrd python-setuptools

pip install virtualenv
virtualenv /opt/graphite
source /opt/graphite/bin/activate

#carbon
git clone https://github.com/graphite-project/carbon.git
cd carbon
python setup.py install
cd ..
#rm -rf carbon

#whisper
git clone https://github.com/graphite-project/whisper.git
cd whisper
python setup.py install
cd ..
#rm -rf whisper

#ceres although we dont use it
git clone https://github.com/graphite-project/ceres.git
cd ceres
python setup.py install
cd ..
#rm -rf ceres

# Get latest pip
pip install --upgrade pip 
pip install requests[security]

sudo apt-get install build-essential python-dev libapache2-mod-wsgi libpq-dev python-psycopg2 -y
sudo apt-get install libssl-dev libffi-dev  -y

#get latest snapshots
git clone https://github.com/graphite-project/graphite-web.git
cd graphite-web
python setup.py install

pip install cryptography
pip install --upgrade scrapy
pip install --upgrade twisted
pip install --upgrade pyopenssl
pip install scandir

# Install carbon and graphite deps 
cat > /tmp/graphite_reqs.txt << EOF
Django==1.7
python-memcached
simplejson
django-tagging
gunicorn
pytz
pyparsing
whitenoise
cryptography
scrapy
twisted
pyopenssl
appdirs
scandir
EOF
#cairocffi
#txAMQP
#tzlocal
sudo pip install -r /tmp/graphite_reqs.txt

python check-dependencies.py

rm /etc/apache2/sites-enabled/*
cp /vagrant/etc/apache2/sites-enabled/graphite.wsgi /opt/graphite/conf
cp /vagrant/etc/apache2/sites-enabled/graphite.conf /etc/apache2/sites-enabled

cd ..
#rm -rf graphite-web

cd /opt/graphite/webapp/graphite
cp local_settings.py.example local_settings.py

sed -i "s/SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = 'a_salty_string'/g" /opt/graphite/webapp/graphite/settings.py
sed -i "s/LOG_DIR = STORAGE_DIR \+ 'log\/webapp\/'/LOG_DIR = '\/var\/log\/apache2\/'/g" /opt/graphite/webapp/graphite/settings.py

echo "" >> /opt/graphite/webapp/graphite/settings.py
echo "BASE_DIR = os.path.dirname(os.path.abspath(__file__)) " >> /opt/graphite/webapp/graphite/settings.py
echo "TEMPLATE_DIRS = (" >> /opt/graphite/webapp/graphite/settings.py
echo "    os.path.join(BASE_DIR, 'templates')," >> /opt/graphite/webapp/graphite/settings.py
echo ")" >> /opt/graphite/webapp/graphite/settings.py

cd /opt/graphite/conf

mkdir examples
mv *.example examples/

cp examples/carbon.conf.example carbon.conf
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
ServerName localhost
Header set Access-Control-Allow-Origin "*"
EOF

PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py syncdb --settings=graphite.settings --noinput
PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py collectstatic --noinput --settings=graphite.settings
#PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py shell --settings=graphite.settings

service apache2 restart

chmod 777 -R /opt/graphite/storage

#sudo -u graphite python /opt/graphite/bin/carbon-cache.py start 

#using this repo to install ganglia 3.4 as it allows for host name overwrites
#add-apt-repository ppa:rufustfirefly/ganglia
# Update and begin installing some utility tools
apt-get -y update
apt-get install ganglia-monitor -y

cp /vagrant/etc/ganglia/gmond.conf /etc/ganglia/gmond.conf
sed -i "s/MONITORNODE/$cfg_ganglia_server/g" /etc/ganglia/gmond.conf
sed -i "s/THISNODEID/$cfg_ganglia_nodes_prefix-graphite/g" /etc/ganglia/gmond.conf
/etc/init.d/ganglia-monitor restart

echo "done!"
