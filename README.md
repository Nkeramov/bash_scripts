# Bash scripts

This project contains some Bash scripts created for making the life easier.

## Description

* **install_nifi.sh** - script for install Apache NiFi, NiFi Registry and NiFi toolkit. 
Accepts the version to be installed as the only parameter. Adds environment variables NIFI_HOME, 
NIFI_REGISTRY_HOME and NIFI_TOOLKIT_HOME. Also script adds aliases for commands to start, stop, restart and get status for NiFi and NiFi Registry. 
If the specified environment variables or command aliases already exist, they are updated, otherwise they will be created. Does not require root rights.
* **system_config_nifi.sh** - script for apply recommended system settings for Apache NiFi described in [Apache NiFi Development Quickstart](https://en.wikipedia.org/wiki/ARTag). Requires root rights.
* **check_java.sh** - script to check if JDK is installed and JAVA_HOME environment variable is correct. Does not require root rights.
* **git_config.sh** - script to configure git options such as user name, email, credentials and aliases.

## Usage

Most of the files are intended to be placed in ~/bin, which is included in the PATH variable by default in most Unix systems.
Make scripts executable by this command: `chmod +x <filename>`.
