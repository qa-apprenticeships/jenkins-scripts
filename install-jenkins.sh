#! /usr/bin/env bash

if type apt > /dev/null; then
  pkg_mgr=apt
  java="openjdk-8-jre"
elif type yum > /dev/null; then
  pkg_mgr=yum
  java="java"
fi

echo "updating and installing dependencies"
sudo ${pkg_mgr} update
sudo ${pkg_mgr} install -y ${java} wget git > /dev/null
sudo ${pkg_mgr} install -y zip > /dev/null

echo "configuring jenkins user"
sudo useradd -m -s /bin/bash jenkins
sudo usermod -a -G sudo jenkins
sudo usermod -a -G docker jenkins
sudo bash -c 'echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99_sudo_include_file'
sudo -k

echo "downloading latest jenkins WAR"
sudo su - jenkins -c "curl -L https://updates.jenkins-ci.org/latest/jenkins.war --output jenkins.war"

echo "setting up jenkins service"
sudo tee /etc/systemd/system/jenkins.service << EOF > /dev/null
[Unit]
Description=Jenkins Server

[Service]
User=jenkins
WorkingDirectory=/home/jenkins
ExecStart=/usr/bin/java -jar /home/jenkins/jenkins.war

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

sudo su - jenkins << EOF
until [ -f .jenkins/secrets/initialAdminPassword ]; do
  sleep 1
  echo "waiting for initial admin password"
done
until [[ -n "\$(cat .jenkins/secrets/initialAdminPassword)" ]]; do
  sleep 1
  echo "waiting for initial admin password"
done
echo "initial admin password: \$(cat .jenkins/secrets/initialAdminPassword)"
EOF
