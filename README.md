Just a few bash scripts to automate process of installing Docker and Docker-Compose

These can be used to install Docker/Docker-Compose on a fresh system. If already installed,
script will update docker-compose binary on an installation.

Currently have scripts for:
- Ubuntu 20.04
- Ubuntu 22.04
- Rocky Linux 8.x

In cases where docker-compose version 1.x is already installed, latest version of docker-compose v2.x 
will be installed along with compose-switch (https://github.com/docker/compose-switch).

