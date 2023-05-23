# Bash scripts

This project contains some Bash scripts created for making the life easier.

## Description

* **install_nifi.sh** - script for install Apache NiFi, NiFi Registry and NiFi toolkit. 
Accepts the version to be installed as the only parameter. Does not require root rights.
* **system_config_nifi.sh** - script for apply recommended system settings for Apache NiFi described in [Apache NiFi Development Quickstart](https://en.wikipedia.org/wiki/ARTag). Requires root rights.
* **check_java.sh** - script to check if JDK is installed and JAVA_HOME environment variable is correct. Does not require root rights.
* **git_config.sh** - script to configure options in git such as alias, user name, email and credentials.

## Usage

Most of the files are intended to be placed in ~/bin, which is included in the PATH variable by default in most Unix systems.
Make scripts executable by this command: `chmod +x <filename>`.
