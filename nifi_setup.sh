#!/usr/bin/env bash

[ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }


if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root"
  echo "Use command 'sudo bash $0'"
  exit 1
fi

# If NiFi and NiFi Registry are installed as a service
#sudo $NIFI_HOME/bin/nifi.sh install nifi_service
#echo "alias NIFI_START=\"sudo service nifi_service start\"" >> ~/.bashrc
#echo "alias NIFI_STOP=\"sudo service nifi_service stop\"" >> ~/.bashrc
#echo "alias NIFI_RESTART=\"sudo service nifi_service restart\"" >> ~/.bashrc
#echo "alias NIFI_STATUS=\"sudo service nifi_service status\"" >> ~/.bashrc
#sudo $NIFI_REGISTRY_HOME/bin/nifi-registry.sh install nifi_registry_service
#echo "alias NIFI_REGISTRY_START=\"sudo service nifi_registry_service start\"" >> ~/.bashrc
#echo "alias NIFI_REGISTRY_STOP=\"sudo service nifi_registry_service stop\"" >> ~/.bashrc
#echo "alias NIFI_REGISTRY_RESTART=\"sudo service nifi_registry_service restart\"" >> ~/.bashrc
#echo "alias NIFI_REGISTRY_STATUS=\"sudo service nifi_registry_service status\"" >> ~/.bashrc

printf "\n" >> /etc/security/limits.conf
# set the maximum number of file descriptors
printf "* hard nofile 50000\n" >> /etc/security/limits.conf
printf "* soft nofile 50000\n" >> /etc/security/limits.conf
# set the maximum number of multi-threaded processes
printf "* hard nproc 10000\n" >> /etc/security/limits.conf
printf "* soft nproc 10000\n" >> /etc/security/limits.conf

sysctl -w net.ipv4.ip_local_port_range="10000 65000"

# setting up the use of swap only as a last resort
printf "\n" >> /etc/sysctl.conf
printf "vm.swappiness = 0" >> /etc/sysctl.conf
