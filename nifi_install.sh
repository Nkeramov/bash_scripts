#!/bin/bash -i

[ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }

source 'bash_color.sh'

# 1 - value to search for
# 2 - value to replace
# 3 - file to perform replacement inline
prop_replace () {
  echo "replacing target file $3"
  sed -i -e "s|^$1=.*$|$1=$2|" $3
}

prop_update(){
  echo "grep '$1' $3"
  if grep -q $1 $3
  then
    echo "replace"
    prop_replace "$1" "$2"
  else
    echo "add"
    echo "$1=$2" >> $3
  fi
  echo "end"
}

uncomment() {
  echo "Uncommenting $2"
  sed -i -e "s|^\#$1|$1|" $2
}

download_cmd="wget"
download_threads_count=5


while [[ "$#" -gt 0 ]]
  do
    case $1 in
      -v|--version) NIFI_VERSION="$2"; shift;;
      -l|--login) NIFI_LOGIN="$2"; shift;;
      -p|--password) NIFI_PASSWORD="$2"; shift;;
      -d|--dir) NIFI_INSTALL_PATH="$2"; shift;;
    esac
    shift
done


if [ -v ${NIFI_VERSION+x} ]; then
  NIFI_VERSION="$(wget -q -O- -T10 https://nifi.apache.org/download.html | grep -oE '(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)' | head -n1)"
  echo "NiFi version not set, ${NIFI_VERSION} will be used instead"
else
  echo "NiFi version set to ${NIFI_VERSION}"
fi

VERSION_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
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
  echo "working dir is $(pwd)"
  # Downloading and extracting NiFi, NiFi Registry, NiFi Toolkit
  echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi ${NIFI_VERSION}"
  eval "${download_cmd} https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip"
  unzip -q nifi-${NIFI_VERSION}-bin.zip -d ${NIFI_INSTALL_PATH}/
  echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi Registry ${NIFI_VERSION}"
  eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-registry-${NIFI_VERSION}-bin.zip"
  unzip -q nifi-registry-${NIFI_VERSION}-bin.zip -d ${NIFI_INSTALL_PATH}/
  echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi Toolkit ${NIFI_VERSION}"
  eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-toolkit-${NIFI_VERSION}-bin.zip"
  unzip -q nifi-toolkit-${NIFI_VERSION}-bin.zip -d ${NIFI_INSTALL_PATH}/
  # Removing temp dir
  cd ~ && rm -rf ${dir_path}
  # Updating envinroment variables
  echo_with_bold_cyan "❯❯❯  Adding envinroment variables"
  source ~/.profile
  # Removing existed NiFi environment variables
  if ! [[ -z "${NIFI_VERSION}" ]]; then
    sed -i '/^export NIFI_VERSION/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_HOME}" ]]; then
    sed -i '/^export NIFI_HOME/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_REGISTRY_HOME}" ]]; then
    sed -i '/^export NIFI_REGISTRY_HOME/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_TOOLKIT_HOME}" ]]; then
    sed -i '/^export NIFI_TOOLKIT_HOME/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_BOOTSTRAP_FILE}" ]]; then
    sed -i '/^export NIFI_BOOTSTRAP_FILE/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_PROPS_FILE}" ]]; then
    sed -i '/^export NIFI_PROPS_FILE/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_REGISTRY_PROPS_FILE}" ]]; then
    sed -i '/^export NIFI_REGISTRY_PROPS_FILE/d' ~/.profile;
  fi
  if ! [[ -z "${NIFI_TOOLKIT_PROPS_FILE}" ]]; then
    sed -i '/^export NIFI_TOOLKIT_PROPS_FILE/d' ~/.profile;
  
  fi
    if ! [[ -z "${NIFI_INPUT}" ]]; then
    sed -i '/^export NIFI_INPUT/d' ~/.profile;
  fi
    if ! [[ -z "${NIFI_OUTPUT}" ]]; then
    sed -i '/^export NIFI_OUTPUT/d' ~/.profile;
  fi

  printf "\n" >> ~/.profile
  # Adding new environment variables
  echo "export NIFI_VERSION=${NIFI_VERSION}" >> ~/.profile
  echo "export NIFI_HOME=${NIFI_INSTALL_PATH}/nifi-${NIFI_VERSION}" >> ~/.profile
  echo "export NIFI_REGISTRY_HOME=${NIFI_INSTALL_PATH}/nifi-registry-${NIFI_VERSION}" >> ~/.profile
  echo "export NIFI_TOOLKIT_HOME=${NIFI_INSTALL_PATH}/nifi-toolkit-${NIFI_VERSION}" >> ~/.profile
  echo "export NIFI_BOOTSTRAP_FILE=${NIFI_INSTALL_PATH}/nifi-${NIFI_VERSION}/bootstrap.conf" >> ~/.profile
  echo "export NIFI_PROPS_FILE=${NIFI_INSTALL_PATH}/nifi-${NIFI_VERSION}/conf/nifi.properties" >> ~/.profile
  echo "export NIFI_REGISTRY_PROPS_FILE=${NIFI_INSTALL_PATH}/nifi-registry-${NIFI_VERSION}/conf/nifi-registry.properties" >> ~/.profile
  echo "export NIFI_TOOLKIT_PROPS_FILE=${NIFI_INSTALL_PATH}/nifi-toolkit-${NIFI_VERSION}/conf/cli.properties" >> ~/.profile

  NIFI_INPUT="${NIFI_INSTALL_PATH}/nifi-${NIFI_VERSION}/input"
  NIFI_OUTPUT="${NIFI_INSTALL_PATH}/nifi-${NIFI_VERSION}/output"


  echo "export NIFI_INPUT=${NIFI_INPUT}" >> ~/.profile
  echo "export NIFI_OUTPUT=${NIFI_OUTPUT}" >> ~/.profile
  mkdir -p ${NIFI_INPUT} ${NIFI_OUTPUT}

  printf "\n" >> ~/.profile
  source ~/.profile
  # Updating aliases for commands (for case when NiFi and NiFi Registry are not installed as a service)
  echo_with_bold_cyan "❯❯❯  Adding aliases for commands"
  . ~/.bashrc
  # Removing existed NiFi command aliases
  if [[ "$(type -t NIFI_START)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_START/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_STOP)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_STOP/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_RESTART)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_RESTART/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_STATUS)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_STATUS/d' ~/.bashrc;
  fi
  printf "\n" >> ~/.bashrc
  # Adding new command aliases
  echo "alias NIFI_START=\"$NIFI_HOME/bin/nifi.sh start\"" >> ~/.bashrc
  echo "alias NIFI_STOP=\"$NIFI_HOME/bin/nifi.sh stop\"" >> ~/.bashrc
  echo "alias NIFI_RESTART=\"$NIFI_HOME/bin/nifi.sh restart\"" >> ~/.bashrc
  echo "alias NIFI_STATUS=\"$NIFI_HOME/bin/nifi.sh status\"" >> ~/.bashrc
  if [[ "$(type -t NIFI_REGISTRY_START)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_REGISTRY_START/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_REGISTRY_STOP)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_REGISTRY_STOP/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_REGISTRY_RESTART)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_REGISTRY_RESTART/d' ~/.bashrc;
  fi
  if [[ "$(type -t NIFI_REGISTRY_STATUS)" -eq "alias" ]]; then
    sed -i '/^alias NIFI_REGISTRY_STATUS/d' ~/.bashrc;
  fi
  printf "\n" >> ~/.bashrc
  echo "alias NIFI_REGISTRY_START=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh start\"" >> ~/.bashrc
  echo "alias NIFI_REGISTRY_STOP=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh stop\"" >> ~/.bashrc
  echo "alias NIFI_REGISTRY_RESTART=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh restart\"" >> ~/.bashrc
  echo "alias NIFI_REGISTRY_STATUS=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh status\"" >> ~/.bashrc
  printf "\n" >> ~/.bashrc

  # Updating NiFi bootstrap.conf settings
  nifi_bootstrap_filename="$NIFI_HOME/conf/bootstrap.conf"
  echo_with_bold_cyan "❯❯❯  Updating NiFi bootstrap.conf (${nifi_bootstrap_filename})"
  # Change default JVM memory settings
  # Minimum (or starting) amount of memory dedicated to the JVM heap space
  nifi_min_memory="2G"
  # Maximum amount of memory allowed to be consumed by the JVM
  nifi_max_memory="4G"
  sed -i "s/^[#]*\s*java.arg.2=.*/java.arg.2=-Xms${nifi_min_memory}/" $nifi_bootstrap_filename
  sed -i "s/^[#]*\s*java.arg.3=.*/java.arg.3=-Xmx${nifi_max_memory}/" $nifi_bootstrap_filename
  echo_with_italics "Updated JVM settings '-Xms' to '${nifi_min_memory}' and '-Xmx' to '${nifi_max_memory}'"
  # Change default JVM timezone (parameter may be absent)
  key_name="java.arg.8"
  key_value="-Duser.timezone=Etc/UTC"
  if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
    echo_with_italics "Added setting '${key_name}' with value '${key_value}'"
    printf "\n" >> $nifi_bootstrap_filename
    echo "$key_name=$key_value" >> $nifi_bootstrap_filename
  else
    echo_with_italics "Updated setting '${key_name}' to value '${key_value}'"
    sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
  fi
  # Change default JVM encodings (parameter may be absent)
  key_name="java.arg.57"
  key_value="-Dfile.encoding=UTF8"
  if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
    echo_with_italics "Added setting '${key_name}' with value '${key_value}'"
    printf "\n" >> $nifi_bootstrap_filename
    echo "$key_name=$key_value" >> $nifi_bootstrap_filename
  else
    echo_with_italics "Updated setting '${key_name}' to value '${key_value}'"
    sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
  fi
  # Fixed encodings for cyrillic symbols (parameter may be absent)
  key_name="java.arg.58"
  key_value="-Dcalcite.default.charset=utf-8"
  if ! grep -R "^[#]*\s*${key_name}=.*" $nifi_bootstrap_filename > /dev/null; then
    echo_with_italics "Added setting '${key_name}' with value '${key_value}'"
    printf "\n" >> $nifi_bootstrap_filename
    echo "$key_name=$key_value" >> $nifi_bootstrap_filename
  else
    echo_with_italics "Updated setting '${key_name}' to value '${key_value}'"
    sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $nifi_bootstrap_filename
  fi

  # Updading NiFi nifi.properties settings
  nifi_properties_filename="$NIFI_HOME/conf/nifi.properties"
  echo_with_bold_cyan "❯❯❯  Updating NiFi nifi.properties (${nifi_properties_filename})"
  # Change default UI banner text
  nifi_banner_text="LOCALHOST"
  sed -i "s/^[#]*\s*nifi.ui.banner.text=.*/nifi.ui.banner.text=${nifi_banner_text}/" $nifi_properties_filename
  echo_with_italics "Updated setting 'nifi.ui.banner.text' to value '${nifi_banner_text}'"
  nifi_sensitive_key=$(openssl rand -hex 20)
  # Change sensitive key
  eval "$NIFI_HOME/bin/nifi.sh set-sensitive-properties-key ${nifi_sensitive_key} &> /dev/null"
  echo_with_italics "Updated setting 'nifi.sensitive.props.key' to value '${nifi_sensitive_key}'"
  if [ -v ${NIFI_LOGIN+x} ]; then
    NIFI_LOGIN="nifi"
    echo_with_italics "NiFi user login not set, '${NIFI_LOGIN}' will be used instead"
  else
    echo_with_italics "NiFi user login set to ${NIFI_LOGIN}"
  fi

  if [ -v ${NIFI_PASSWORD+x} ]; then
    NIFI_PASSWORD="nifi_password"
    echo_with_italics "NiFi user password not set, '${NIFI_PASSWORD}' will be used instead"
  else
    echo_with_italics "NiFi user passsword set to ${NIFI_PASSWORD}"
  fi
  eval "$NIFI_HOME/bin/nifi.sh set-single-user-credentials ${NIFI_LOGIN} ${NIFI_PASSWORD} &> /dev/null"
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
  if [ "$k" -le $kmax ]; then
      echo_with_bold_cyan "❯❯❯  NiFi started at ${nifi_web_interface_link}/nifi/"
    else
      echo_with_bold_red "ERROR, NiFi not started"
  fi
  exec bash
  #echo "To get the username and password use the command: grep Generated $NIFI_HOME/logs/nifi-app*log"
else
  echo_with_bold_red "ERROR, passed version did not match version regex"
fi
