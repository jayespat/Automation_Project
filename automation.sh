#!/bin/bash
#
#############################################################
# This script installs 'apache2' server on this machine and #
# does some housekeeping work by archiving log files.       #
#############################################################
#
#############################################################
# Define variables used in this script                      #
#############################################################
#
s3_bucket="upgrad-jayesh"
myname="Jayesh"
#
#############################################################
# Check if 'apache2' is installed on the machine.           #
#     - Install 'apache2' if not installed already.         #
#     - Don't install again if it is already installed.     #
#############################################################
#
apachecheck=$(sudo dpkg --get-selections | grep -m 1 apache2)
apachecount=$(echo $apachecheck| grep -c "apache2")
#
if [ "$apachecount" -gt "0" ]; then
	echo '**apache is already installed on this machine'
else
	echo '**apache is not installed'
	echo '**Package update started on machine'
	sudo apt update -y
	echo '**Package update completed'
	echo '**Installing apache on this machine'
	sudo apt install apache2 -y
	echo '**apache is successfully installed on this machine'
fi
#
#############################################################
# Check if 'apache2' is running on the machine.             #
#     - Start the service if not running already.           #
#     - Do nothing if already in running state.             #
#############################################################
#
apachestat=$(systemctl status apache2 | grep -m 1 "Active")
#
if [[ $apachestat == *"(running)"* ]]; then
	echo '**apache2 is already Active and running'
else
	echo '**apache2 service is inactive - starting it'
	systemctl start apache2
	echo '**apache2 is running now'
fi	
#
#############################################################
# Check if 'apache2' is enabled to restart when the machine #
# reboots.
#     - Enable the service if it is 'disabled'.             #
#     - Do nothing if already 'enabled'                     #
#############################################################
#
apache_enable=$(systemctl is-enabled apache2 | grep -m 1 "enabled")
#
if [[ $apache_enable == *"enabled"* ]]; then
        echo '**apache service is already enabled'
else
        echo '**apache service is not enabled - enabling it now'
        systemctl enable apache2
        echo '**apache service is enabled now'
fi
#
#############################################################
# Create a .tar file with all the log files for 'apache2'   #
# service                                                   #
#############################################################
#
timestamp=$(date '+%d%m%Y-%H%M%S')
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log
#
#############################################################
# Copy the tar file to S3 bucket                            #
#############################################################
#
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
#
#############################################################
# Empty the log files from EC2 instance after copying to    #
# S3 bucket and also delete the .tar files from /tmp/ to    #
# save the space.                                           #
#############################################################
#
truncate -s 0 /var/log/apache2/*.log
#
rm -rf /tmp/*.tar
#
exit
#
