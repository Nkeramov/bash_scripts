# Bash scripts

[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![license](https://img.shields.io/badge/licence-MIT-green.svg)](https://opensource.org/licenses/MIT)


This project contains some Bash scripts created for making the life easier.

## Description

* **nifi_install.sh** - script for install Apache NiFi, NiFi Registry and NiFi toolkit. 
Accepts args: 
  1. the NiFi version to be installed (-v or --version)
  2. the NiFi user login (-l or --login)
  3. the NiFi user password (-p or --password)
  4. the installation dir (-d or -- dir)

Make sure your password is at least 12 characters long.

The version may not be specified, in which case the latest version will be installed

Adds environment variables: 
  1. NIFI_VERSION
  2. NIFI_HOME
  3. NIFI_REGISTRY_HOME
  4. NIFI_TOOLKIT_HOME
  5. NIFI_BOOTSTRAP_FILE
  6. NIFI_PROPS_FILE
  7. NIFI_REGISTRY_PROPS_FILE
  8. NIFI_TOOLKIT_PROPS_FILE
  9. NIFI_INPUT
  10. NIFI_OUTPUT
Also script adds aliases for commands to start, stop, restart and get status for NiFi and NiFi Registry:
  1. NIFI_START
  2. NIFI_STOP
  3. NIFI_RESTART
  4. NIFI_STATUS
  5. NIFI_REGISTRY_START
  6. NIFI_REGISTRY_STOP
  7. NIFI_REGISTRY_RESTART
  8. NIFI_REGISTRY_STATUS

Use command to run:
`
  bash -i ./nifi_install.sh -v 1.23.2 -l admin -p strong_password -d /opt
`

If the specified environment variables or command aliases already exist, they are updated, otherwise they will be created. Does not require root rights.

Running in interactive mode is required to correctly detect existing aliases.

* **nifi_setup.sh** - script for apply recommended system settings for Apache NiFi described in [Apache NiFi Development Quickstart](https://en.wikipedia.org/wiki/ARTag). Requires root rights.
* **check_java.sh** - script to check if JDK is installed and JAVA_HOME environment variable is correct. Does not require root rights.
* **git_config.sh** - script to configure git options such as username, email, credentials and aliases.
* **google_drive_download.sh** - script to download files from Google Drive with wget. Arguments file ID and output filename.
* **bash_color.sh** - script for formatting text output (setting color, background, style).

## Usage

Most of the files are intended to be placed in ~/bin, which is included in the PATH variable by default in most Unix systems.
Make scripts executable by this command: `chmod +x <filename>`.

## Contributing

If you want to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push to your fork and create a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
