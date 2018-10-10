#!/bin/bash
sudo yum -y update
sudo yum install -y httpd java-1.8.0-openjdk tomcat8 tomcat8-webapps tomcat8-docs-webapp tomcat8-admin-webapps
sudo service tomcat8 start
