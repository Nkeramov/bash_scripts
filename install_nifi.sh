#!/usr/bin/env bash


echo_with_red_color() {
  echo -e '\e[1;31m'$1'\e[m';
}

echo_with_cyan_color() {
  echo -e '\e[1;36m'$1'\e[m';
}

download_cmd="wget"
download_threads_count=5

if [[ $# -eq 1 ]]; then
  NIFI_VERSION=$1
  VERSION_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
  echo "passed version - $NIFI_VERSION"
  if [[ "$NIFI_VERSION" =~ $VERSION_REGEX ]]; then
    # Selecting download command
    if ! command -v aria2c &> /dev/null
    then
      echo "aria2c is not installed, wget will be used for downloads"
    else
      echo "aria2c is installed and will be used for downloads"
      download_cmd="aria2c -x${download_threads_count} --summary-interval=0"
    fi
    # Creating temp dir
    dir_path="$(uuidgen)"
    cd ~
    mkdir ${dir_path}
    cd ${dir_path}
    echo "current dir is $(pwd)"
    # Downloading and extracting NiFi, NiFi Registry, NiFi Toolkit
    echo_with_cyan_color "❯❯❯  Downloading and extracting Apache NiFi"
    eval "${download_cmd} https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip"
    unzip -q nifi-${NIFI_VERSION}-bin.zip -d /opt/
    echo_with_cyan_color "❯❯❯  Downloading and extracting Apache NiFi Registry"
    eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-registry-${NIFI_VERSION}-bin.zip"
    unzip -q nifi-registry-${NIFI_VERSION}-bin.zip -d /opt/
    echo_with_cyan_color "❯❯❯  Downloading and extracting Apache NiFi Toolkit"
    eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-toolkit-${NIFI_VERSION}-bin.zip"
    unzip -q nifi-toolkit-${NIFI_VERSION}-bin.zip -d /opt/
    # Removing temp dir
    cd ~ && rm -rf ${dir_path}
    # Updating envinroment variables
    echo_with_cyan_color "❯❯❯  Adding envinroment variables"
    source ~/.profile    
    if ! [[ -z "${NIFI_HOME}" ]]; then
      sed -i '/^export NIFI_HOME/d' ~/.profile;
    fi
    if ! [[ -z "${NIFI_REGISTRY_HOME}" ]]; then
      sed -i '/^export NIFI_REGISTRY_HOME/d' ~/.profile;
    fi
    if ! [[ -z "${NIFI_TOOLKIT_HOME}" ]]; then
      sed -i '/^export NIFI_TOOLKIT_HOME/d' ~/.profile;
    fi
    printf "\n" >> ~/.profile
    echo "export NIFI_HOME=/opt/nifi-${NIFI_VERSION}" >> ~/.profile
    echo "export NIFI_REGISTRY_HOME=/opt/nifi-registry-${NIFI_VERSION}" >> ~/.profile
    echo "export NIFI_TOOLKIT_HOME=/opt/nifi-toolkit-${NIFI_VERSION}" >> ~/.profile
    printf "\n" >> ~/.profile
    source ~/.profile
    
    # Updating aliases for commands (for case when NiFi and NiFi Registry are not installed as a service)
    echo_with_cyan_color "❯❯❯  Adding aliases for commands"
    source ~/.bashrc
    if [ "$(type -t NIFI_START)" = 'alias' ]; then
      sed -i '/^alias NIFI_START/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_STOP)" = 'alias' ]; then
      sed -i '/^alias NIFI_STOP/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_RESTART)" = 'alias' ]; then
      sed -i '/^alias NIFI_RESTART/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_STATUS)" = 'alias' ]; then
      sed -i '/^alias NIFI_STATUS/d' ~/.bashrc;
    fi
    printf "\n" >> ~/.bashrc
    echo "alias NIFI_START=\"$NIFI_HOME/bin/nifi.sh start\"" >> ~/.bashrc
    echo "alias NIFI_STOP=\"$NIFI_HOME/bin/nifi.sh stop\"" >> ~/.bashrc
    echo "alias NIFI_RESTART=\"$NIFI_HOME/bin/nifi.sh restart\"" >> ~/.bashrc
    echo "alias NIFI_STATUS=\"$NIFI_HOME/bin/nifi.sh status\"" >> ~/.bashrc
    if [ "$(type -t NIFI_REGISTRY_START)" = 'alias' ]; then
      sed -i '/^alias NIFI_REGISTRY_START/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_REGISTRY_STOP)" = 'alias' ]; then
      sed -i '/^alias NIFI_REGISTRY_STOP/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_REGISTRY_RESTART)" = 'alias' ]; then
      sed -i '/^alias NIFI_REGISTRY_RESTART/d' ~/.bashrc;
    fi
    if [ "$(type -t NIFI_REGISTRY_STATUS)" = 'alias' ]; then
      sed -i '/^alias NIFI_REGISTRY_STATUS/d' ~/.bashrc;
    fi
    printf "\n" >> ~/.bashrc
    echo "alias NIFI_REGISTRY_START=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh start\"" >> ~/.bashrc
    echo "alias NIFI_REGISTRY_STOP=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh stop\"" >> ~/.bashrc
    echo "alias NIFI_REGISTRY_RESTART=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh restart\"" >> ~/.bashrc
    echo "alias NIFI_REGISTRY_STATUS=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh status\"" >> ~/.bashrc
    printf "\n" >> ~/.bashrc
    source ~/.bashrc
    #eval "$(cat ~/.bashrc | tail -n +10)"

    # Updating NiFi bootstrap.conf settings
    nifi_bootstrap_filename="$NIFI_HOME/conf/bootstrap.conf"
    echo_with_cyan_color "❯❯❯  Updating NiFi bootstrap.conf (${nifi_bootstrap_filename})"
    # Change default JVM memory settings
    nifi_min_memory="2G"
    nifi_max_memory="4G"
    sed -i "s/^[#]*\s*java.arg.2=.*/java.arg.2=-Xms${nifi_min_memory}/" $nifi_bootstrap_filename
    sed -i "s/^[#]*\s*java.arg.3=.*/java.arg.3=-Xmx${nifi_max_memory}/" $nifi_bootstrap_filename
    echo "Updated JVM settings '-Xms' to '${nifi_min_memory}' and '-Xmx' to '${nifi_max_memory}'"
    # Change default JVM timezone (parameter may be absent)
    key_name="java.arg.8"
    key_value="-Duser.timezone=Etc/UTC"
    if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
      echo "Added setting '${key_name}' with value '${key_value}'"
      printf "\n" >> $nifi_bootstrap_filename
      echo "$key_name=$key_value" >> $nifi_bootstrap_filename
    else
      echo "Updated setting '${key_name}' to value '${key_value}'"
      sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
    fi
    # Change default JVM encodings (parameter may be absent)
    key_name="java.arg.57"
    key_value="-Dfile.encoding=UTF8"
    if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
      echo "Added setting '${key_name}' with value '${key_value}'"
      printf "\n" >> $nifi_bootstrap_filename
      echo "$key_name=$key_value" >> $nifi_bootstrap_filename
    else
      echo "Updated setting '${key_name}' to value '${key_value}'"
      sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
    fi
    # Fixed encodings for cyrillic symbols (parameter may be absent)
    key_name="java.arg.58"
    key_value="-Dcalcite.default.charset=utf-8"
    if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
      echo "Added setting '${key_name}' with value '${nifi_bootstrap_filename}'"
      printf "\n" >> $key_value
      echo "$key_name=$key_value" >> $nifi_bootstrap_filename
    else
      echo "Updated setting '${key_name}' to value '${key_value}'"
      sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
    fi



    # Updading NiFi nifi.properties settings
    nifi_properties_filename="$NIFI_HOME/conf/nifi.properties"
    echo_with_cyan_color "❯❯❯  Updating NiFi nifi.properties (${nifi_properties_filename})"
    # Change default UI banner text
    nifi_banner_text="LOCALHOST"
    sed -i "s/^[#]*\s*nifi.ui.banner.text=.*/nifi.ui.banner.text=${nifi_banner_text}/" $nifi_properties_filename
    echo "Updated setting 'nifi.ui.banner.text' to value '${nifi_banner_text}'"
    
    nifi_sensitive_key=$(openssl rand -hex 20)
    # Change sensitive key
    eval "$NIFI_HOME/bin/nifi.sh set-sensitive-properties-key ${nifi_sensitive_key} &> /dev/null"
    echo "Updated setting 'nifi.sensitive.props.key' to value '${nifi_sensitive_key}'"
    nifi_login="nifi"
    nifi_password="nifi_password"
    echo "NiFi Login = ${nifi_login}"
    echo "NiFi Passsword = ${nifi_password}"
    eval "$NIFI_HOME/bin/nifi.sh set-single-user-credentials ${nifi_login} ${nifi_password} &> /dev/null"
    # Start NiFi and wait
    eval "$NIFI_HOME/bin/nifi.sh start &> /dev/null"
    echo -n "Waiting for NiFi start ..."
    k=1
    kmax=150
    nifi_web_interface_link=""
    while [[ $k -le $kmax ]] && [[ "$nifi_web_interface_link" = "" ]]
    do
            nifi_web_interface_link=$(grep "org.apache.nifi.web.server.JettyServer https" $NIFI_HOME/logs/nifi-app*.log | tail -1 | grep -Eo '(http|https)://[^/"]+')
            echo -n '.'
            ((k=k+1))
            sleep 1
    done
    printf "\n"
    if [ "$k" -le $kmax ];
      then
        echo_with_cyan_color "❯❯❯  NiFi started at ${nifi_web_interface_link}/nifi/"
      else
        echo_with_red_color "ERROR, NiFi not started"
    fi
    
    #echo "To get the username and password use the command: grep Generated $NIFI_HOME/logs/nifi-app*log"
  else
		echo_with_red_color "ERROR, passed version did not match version regex"
	fi
else
	echo_with_red_color "ERROR, version is not passed or passed more than one argument"
fi



