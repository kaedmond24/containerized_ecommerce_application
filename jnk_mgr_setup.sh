#!/bin/bash

# Install addtional packages
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa 
apt-get install -y python3.7
apt-get install -y python3.7-venv
apt-get install -y build-essential
apt-get install -y libmysqlclient-dev
apt-get install -y python3.7-dev

# Install Jenkins dependencies 
apt-get install -y fontconfig
apt-get install -y openjdk-11-jre

# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins apt repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
apt-get update
apt-get install -y jenkins
