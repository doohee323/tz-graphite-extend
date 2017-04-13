#!/usr/bin/env bash

echo "Reading config...." >&2
source /vagrant/setup.rc

apt-get update -y 
apt-get upgrade -y 
apt-get install python-software-properties libtool autoconf automake uuid-dev build-essential wget curl git monit -y

apt-get autoremove -y
apt-get install --assume-yes apache2 apache2-mpm-worker apache2-utils python-pip libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libffi-dev python-dev python3-minimal libapache2-mod-wsgi libaprutil1-ldap memcached python-cairo-dev python-django python-ldap python-memcache python-pysqlite2 sqlite3 python-rrd python-setuptools

sudo apt-get install build-essential python-dev libapache2-mod-wsgi libpq-dev python-psycopg2 -y
sudo apt-get install libssl-dev libffi-dev  -y

##########################################
# Make virtualenv
##########################################
pip install virtualenv
virtualenv /opt/graphite
source /opt/graphite/bin/activate

##########################################
# install carbon
##########################################
git clone https://github.com/graphite-project/carbon.git
cd carbon
python setup.py install
cd ..

##########################################
# install whisper
##########################################
git clone https://github.com/graphite-project/whisper.git
cd whisper
python setup.py install
cd ..

##########################################
# install graphite-web
##########################################
git clone https://github.com/graphite-project/graphite-web.git
cd graphite-web

##########################################
# Get latest pip
##########################################
pip install --upgrade pip 
pip install requests[security]
python setup.py install

pip install cryptography
pip install --upgrade scrapy
pip install --upgrade twisted
pip install --upgrade pyopenssl
pip install scandir

##########################################
# Install carbon and graphite deps
##########################################
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
sudo pip install -r /tmp/graphite_reqs.txt

python check-dependencies.py

##########################################
# graphite apache2 setting
##########################################
rm /etc/apache2/sites-enabled/*
cp /vagrant/etc/apache2/sites-enabled/graphite.wsgi /opt/graphite/conf
cp /vagrant/etc/apache2/sites-enabled/graphite.conf /etc/apache2/sites-enabled

##########################################
# local_settings.py, settings.py
##########################################
cd /opt/graphite/webapp/graphite
cp local_settings.py.example local_settings.py

sed -i "s/SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = 'a_salty_string'/g" /opt/graphite/webapp/graphite/settings.py
sed -i "s/LOG_DIR = STORAGE_DIR \+ 'log\/webapp\/'/LOG_DIR = '\/var\/log\/apache2\/'/g" /opt/graphite/webapp/graphite/settings.py

echo "" >> /opt/graphite/webapp/graphite/settings.py
echo "BASE_DIR = os.path.dirname(os.path.abspath(__file__)) " >> /opt/graphite/webapp/graphite/settings.py
echo "TEMPLATE_DIRS = (" >> /opt/graphite/webapp/graphite/settings.py
echo "    os.path.join(BASE_DIR, 'templates')," >> /opt/graphite/webapp/graphite/settings.py
echo ")" >> /opt/graphite/webapp/graphite/settings.py

##########################################
# graphite examples
##########################################
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

##########################################
# apache2.conf
##########################################
a2enmod headers

cat << 'EOF'  >> /etc/apache2/apache2.conf
ServerName localhost
Header set Access-Control-Allow-Origin "*"
EOF

service apache2 restart

##########################################
# make database
##########################################
PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py syncdb --settings=graphite.settings --noinput
PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py collectstatic --noinput --settings=graphite.settings

chmod 777 -R /opt/graphite/storage

sudo -u graphite python /opt/graphite/bin/carbon-cache.py start 

echo "done!"
