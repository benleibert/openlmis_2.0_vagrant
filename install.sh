#!/bin/bash
#This is an installation script for OpenLMIS 2.0 for Ubuntu 14.04 LTS

echo "Provisioning OpenLMIS"
sudo apt-get update

#Postgresql in Ubuntu 14.04 is version is 9.3 and we need to install 9.2. 
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

#Install Postgres v 9.2 and the contrib package. Also set the postgres password and create the openlmis database
sudo apt-get install -y postgresql-9.2
sudo apt-get install -y postgresql-contrib-9.2 #So we can create extensions
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'p@ssw0rd';"

#Install OpenJDK, git and unzip
sudo apt-get install -y openjdk-7-jdk
sudo apt-get install -y git curl unzip

#Install gradle
sudo add-apt-repository -y ppa:cwchien/gradle
sudo apt-get update
sudo apt-get install -y gradle-2.3

#Install node.js
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs

#Clone repo and resolve submodule dependencies
git clone https://github.com/openlmis/open-lmis.git -b 2.0 --single-branch
cd open-lmis
git submodule init
git submodule update

#Install NPM dependencies
sudo apt-get install -y g++
sudo npm install -g grunt-cli
cd modules/openlmis-web

#Since we're working in a headless environment, we need to use the PhantomJS karma browser for testing
#We have to make the following file changes:
#1 add the karma-phantomjs-launcher to the npm install packages
sed -e '/"karma-firefox-launcher": "^0.1.4",/a\    "karma-phantomjs-launcher": "^0.2.1",\n    "phantomjs": "^1.9.19",' -i package.json
#2 add the plugin as a dependency in the karma.config.js
sed -e "s/'karma-firefox-launcher'/'karma-firefox-launcher',\n      'karma-phantomjs-launcher'/" -i karma.config.js
#3 Change the browser from Firefox to PhantomJS
sed -e "s/browsers: \['Firefox'\],/browsers: \['PhantomJS'\],/" -i karma.config.js

#Proceed with npm package install globally
sudo npm install -g
cd ../..

#may need to change permissions on npm modules
#sudo chown -R vagrant:vagrant /usr/lib/nodejs/ /usr/lib/node_modules/

#Run all gradle tasks and save the output for debugging
gradle clean setupdb setupExtensions seed build testseed --continue 2>&1 | tee ~/openlmis_build_output.txt

echo "Running OpenLMIS. Navigate to http://192.168.33.220:9091/ to continue. Default username is 'Admin123' and password is 'Admin123'"
gradle run
