#!/usr/bin/env bash

# Check if the script is run as root
if [ $(whoami) != "root" ]; then
    echo "You need to run this script as root"
    exit 1
fi

# Get current working directory
WORKDIR=$(pwd)

# Get the distribution ID
OS=$(awk -F: 'NR==3{ gsub("\"", ""); split($0, a, "=") } END { print a[2] }' /etc/os-release)

# Install GCC compiler and Make on Ubuntu
if [ $OS == "ubuntu" ] || [ $OS == "debian" ]; then
    apt-get -y update
    apt-get -y install gcc make

#Install GCC compiler and Make on Fedora
elif [ $OS == "fedora" ]; then
    dnf -y update
    dnf -y install make gcc

# Install GCC compiler on CentOS/RHEL
elif [ $OS == "centos" ] || [ $OS == "rhel" ]; then
    yum -y install gcc
fi

# Download and install Redis
cd /tmp
curl -0 http://download.redis.io/redis-stable.tar.gz -o redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make 
make install

# Create user and directories
mkdir -p /etc/redis /var/redis/6379 /var/run/redis /var/log/redis
useradd -r -U redis -s /sbin/nologin
usermod -L redis

# Copy the configuration files
cp $WORKDIR/6379.conf /etc/redis/6379.conf
cp $WORKDIR/redis.service /etc/systemd/system/

# Adjust folder permissions
chmod 755 /var/run/redis
chmod 755 /var/log/redis
chmod 755 -R /var/redis

# Adjust folder ownership
chown redis:redis /var/run/redis
chown redis:redis /var/log/redis
chown redis:redis -R /var/redis

# Some tweaking as recommended
sysctl vm.overcommit_memory=1
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Start and enable Redis
systemctl daemon-reload
systemctl start redis && systemctl enable redis

# Cleanup
yes | rm -r /tmp/redis-stable
rm /tmp/redis-stable.tar.gz