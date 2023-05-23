if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root"
  echo "Use command 'sudo bash $0'"
  exit 1
fi

printf "\n" >> /etc/security/limits.conf
printf "* hard nofile 50000\n" >> /etc/security/limits.conf
printf "* soft nofile 50000\n" >> /etc/security/limits.conf
printf "* hard nproc 10000\n" >> /etc/security/limits.conf
printf "* soft nproc 10000\n" >> /etc/security/limits.conf

sudo sysctl -w net.ipv4.ip_local_port_range="10000 65000"


printf "\n" >> /etc/sysctl.conf
printf "vm.swappiness = 0\n" >> /etc/sysctl.conf
