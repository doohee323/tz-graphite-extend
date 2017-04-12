
#!/usr/bin/env bash

echo "Making Base...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

# Update and begin installing some utility tools
sudo apt-get update -y 
sudo apt-get upgrade -y 
sudo apt-get autoremove -y
sudo apt-get install python-software-properties libtool autoconf automake uuid-dev build-essential wget curl git monit -y
#sudo rm -rf /var/lib/apt/lists/*
sudo apt-get install apache2 libapache2-mod-wsgi apache2-mpm-worker apache2-utils -y 
sudo apt-get install libapr1 libaprutil1 libffi-dev libaprutil1-ldap memcached -y 
sudo apt-get install python-pip python-dev python3-minimal python-cairo-dev python-django python-ldap python-memcache python-rrd python-setuptools -y 

#pip install virtualenv

#virtualenv /opt/graphite
#source /opt/graphite/bin/activate

#carbon
#git clone https://github.com/graphite-project/carbon.git
#cd /home/vagrant/carbon
#python setup.py install
cd /home/vagrant
#rm -rf carbon

#whisper
#git clone https://github.com/graphite-project/whisper.git
#cd /home/vagrant/whisper
#python setup.py install
#cd /home/vagrant
#rm -rf whisper

#ceres although we dont use it
#git clone https://github.com/graphite-project/ceres.git
#cd /home/vagrant/ceres
#sudo python setup.py install
#cd /home/vagrant
#rm -rf ceres

# Get latest pip
sudo pip install --upgrade pip 
sudo pip install requests[security]

#get latest snapshots
#git clone https://github.com/graphite-project/graphite-web.git
#cd /home/vagrant/graphite-web
#python setup.py install
echo "==========================================="
echo " install graphite "
echo "==========================================="
sudo apt-get install graphite-web -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y --force-yes install graphite-carbon
sudo cp -Rf /vagrant/resources/graphite/local_settings.py /etc/graphite/local_settings.py

#sudo cp /vagrant/resources/apache2/sites-available/graphite.wsgi /opt/graphite/conf
sudo cp -Rf /vagrant/resources/apache2/sites-available/apache2-graphite.conf /etc/apache2/sites-available/apache2-graphite.conf
sudo a2enmod wsgi

sudo cp -Rf /vagrant/resources/apache2/ports.conf /etc/apache2/ports.conf
sudo a2dissite 000‐default
sudo a2ensite apache2‐graphite
sudo service apache2 reload

#rm -rf graphite-web

#cd /etc/graphite
#sudo cp local_settings.py.example local_settings.py

#sudo sed -i "s/SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = 'a_salty_string'/g" /etc/graphite/settings.py
#sudo sed -i "s/LOG_DIR = STORAGE_DIR \+ 'log\/webapp\/'/LOG_DIR = '\/var\/log\/apache2\/'/g" /etc/graphite/settings.py

#sudo rm -Rf /opt/graphite/conf/examples
#sudo mkdir /opt/graphite/conf/examples
#sudo mv /opt/graphite/conf/*.example /opt/graphite/conf/examples/

useradd -p `openssl passwd password` graphite
chown -R graphite:graphite /opt/graphite

#enable headers
a2enmod headers

cat << 'EOF'  >> /etc/apache2/apache2.conf
ServerName localhost
EOF

service apache2 restart

chmod 777 -R /var/lib/graphite/whisper

#sudo -u graphite python /opt/graphite/bin/carbon-cache.py start 

echo "==========================================="
echo " install postgres "
echo "==========================================="
sudo apt-get install postgresql -y
sudo apt-get install libpq-dev -y
sudo apt-get install python-psycopg2 -y

sudo cp -Rf /vagrant/resources/postgresql/9.3/main/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
#local   all             postgres                                trust
#local   all             all                                     trust
#host    all             all             127.0.0.1/32            trust
#host    all             all             ::1/128                 trust

sudo cp -Rf /vagrant/resources/postgresql/9.3/main/init.sql /etc/postgresql/9.3/main/init.sql
#CREATE USER graphite WITH PASSWORD 'a_salty_string';
#CREATE DATABASE graphite WITH OWNER graphite;

sudo service postgresql restart

sudo psql -h localhost -U postgres -a -w -f /etc/postgresql/9.3/main/init.sql

#psql -h localhost -U postgres
#postgres=# \l
#                                  List of databases
#   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
#-----------+----------+----------+-------------+-------------+-----------------------
# graphite  | graphite | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
# \q

echo "done!"

exit 0

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