#!/bin/bash
sudo yum -y update
sudo yum install -y httpd java-1.8.0-openjdk

cat >> /etc/httpd/conf/httpd.conf << EOL
<VirtualHost *:80>
ServerName <mydomain>
ServerAlias <*.mydomain>
ProxyRequests off
ProxyPass / http://${elb_dns}:8080/
ProxyPassReverse / http://${elb_dns}:8080/
</VirtualHost>
EOL
sudo service httpd start
