#!/bin/bash

if [ $(whoami) != root ] ; then
	echo "Please run this script as root user or with sudo! Exiting."
	exit 1
fi

OSV=$(cat /etc/rocky-release)
if $(echo "$OSV" | grep -vq "Rocky Linux release 8") ; then
	echo "This script is intended for Rocky Linux version 8.x"
	exit 1
fi

## Ensure system is fully updated
echo ""
echo "It is highly recommended to fully update the system prior to running this installation script"
echo "e.g.: dnf update"
echo "Please exit the script now (CTRL-c) and complete any outstanding system updates if necessary"
read -p "Press ENTER to proceed to install/upgrade Docker & Docker-Compose on this system"

install_docker () {
	#PREREQS
	dnf update && dnf install epel-release
	dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

	#INSTALL DOCKER
	dnf update -y
	dnf install -y docker-ce docker-ce-cli containerd.io

	#usermod -aG docker $USER

	docker --version || exit 1
	systemctl enable --now docker
}

download_compose () {
	curl -fL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose && chmod +x /usr/libexec/docker/cli-plugins/docker-compose

	curl -fL https://github.com/docker/compose-switch/releases/latest/download/docker-compose-linux-amd64 -o /usr/local/bin/compose-switch && chmod +x /usr/local/bin/compose-switch
}

upgrade_version_1 () {
	mv /usr/local/bin/docker-compose /usr/local/bin/docker-compose-v1
	update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/docker-compose-v1 1
	update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99
}

revert_compose () {
	#If Download is broken, revert to previous version
	mv /tmp/docker-compose.old /usr/libexec/docker/cli-plugins/docker-compose
	mv /tmp/compose-switch.old /usr/local/bin/compose-switch
}

cleanup_tmp () {
	rm -rf /tmp/docker-compose.old
	rm -rf /tmp/compose-switch.old
	rm -rf /tmp/compose-version.txt
}

if ! command -v docker ; then
       install_docker
fi       

docker-compose --version > /tmp/compose-version.txt

if ! command -v docker-compose ; then
	download_compose
else
	if [ -f /usr/libexec/docker/cli-plugins/docker-compose ] ; then
		mv /usr/libexec/docker/cli-plugins/docker-compose /tmp/docker-compose.old
		mv /usr/local/bin/compose-switch /tmp/compose-switch.old
		download_compose || revert_compose
	else
		download_compose
	fi
fi

if [ -f /usr/local/bin/docker-compose ] ; then
	if $(grep -q "docker-compose version 1" /tmp/compose-version.txt) ; then
		upgrade_version_1
	fi
else
	update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99
fi

docker-compose --version

cleanup_tmp

echo ""
echo "Docker and docker-compose has been installed/upgraded.  To allow your user account to run docker commands:"
echo "sudo usermod -aG docker <username>"
echo ""
exit 0
