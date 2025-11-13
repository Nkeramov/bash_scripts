#!/usr/bin/env bash

[ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }


source './bash_color.sh'
source './check_java.sh'

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

command_exists() {
  command -v "${1}" > /dev/null 2>& 1
}

uncomment() {
  echo "Uncommenting $2"
  sed -i -e "s|^\#$1|$1|" $2
}

generate_random_string() {
  local length="$1"
  openssl rand -base64 "$((length * 3 / 4 + 1))" | tr -dc A-Za-z0-9_ | head -c "$length"
}

remove_env_variable() {
  local var_name="$1"
  local file=${2:-~/.profile}
  if [[ -v "${var_name}" || -n "${!var_name+x}" ]]; then
    sed -i "/^export ${var_name}=/d" "$file"
    sed -i "/^export ${var_name}\$/d" "$file"
  fi
}

remove_alias() {
    local alias_name="$1"
    local target_file=${2:-~/.bashrc}

    if ! is_alias "$alias_name"; then
        #echo "Alias '${alias_name}' does not exist, nothing to remove"
        return 1
    fi
    echo "Removing alias '${alias_name}' from ${target_file}"

    if sed -i "/^alias ${alias_name}=/d" "${target_file}"; then
        echo "Successfully removed alias '${alias_name}'"
        unalias "$alias_name" 2>/dev/null
        return 0
    else
        echo "Failed to remove alias '${alias_name}' from ${target_file}" >&2
        return 1
    fi
}

is_alias() {
    if [[ "$(type -t "$1")" = "alias" ]]; then
        return 0
    else
        return 1
    fi
}

log() { echo  $(date "+%Y-%m-%d %H:%m:%S") $1; }
log_info() { log "INFO: $1"; }
log_error() { log "ERROR: $1"; exit 1; }


if [[ $- == *i* ]]; then
    echo "This shell is interactive"

    while [[ "$#" -gt 0 ]]
      do
        case $1 in
          -v|--version) NIFI_VERSION_ARG="$2"; shift;;
          -l|--login) NIFI_LOGIN_ARG="$2"; shift;;
          -p|--password) NIFI_PASSWORD_ARG="$2"; shift;;
          -d|--dir) NIFI_INSTALL_PATH_ARG="$2"; shift;;
        esac
        shift
    done

    if [ -z ${NIFI_LOGIN_ARG+x} ]; then
      NIFI_LOGIN_ARG="nifi"
      echo_with_italics "NiFi user login not set, '${NIFI_LOGIN_ARG}' will be used instead"
    else
      echo_with_italics "NiFi user login will be set to ${NIFI_LOGIN_ARG}"
    fi

    if [ -z ${NIFI_PASSWORD_ARG+x} ]; then
      NIFI_PASSWORD_ARG=$(generate_random_string 16)
      echo_with_italics "NiFi user password not set, '${NIFI_PASSWORD_ARG}' will be used instead"
    else
      if [ ${#NIFI_PASSWORD_ARG} -lt 12 ]; then
        echo_with_bold_red "Error: Password must be at least 12 characters long." >&2
        exit 1
      else
        echo_with_italics "NiFi user passsword will be set to ${NIFI_PASSWORD_ARG}"
      fi
    fi

    readonly VERSION_SEARCH_REGEX="(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    readonly VERSION_STRICT_REGEX="^${VERSION_SEARCH_REGEX}$"

    if [ -z ${NIFI_VERSION_ARG+x} ]; then
      NIFI_VERSION_ARG="$(wget -q -O- -T10 https://nifi.apache.org/download.html | grep -oE "${VERSION_SEARCH_REGEX}" | head -n1)"
      echo_with_italics "NiFi version not passed, $NIFI_VERSION_ARG will be used"
    else
      if [[ "$NIFI_VERSION_ARG" =~ $VERSION_STRICT_REGEX ]]; then
        echo_with_italics "NiFi version $NIFI_VERSION_ARG will be used"
      else
        echo_with_bold_red "ERROR, passed NiFi version $NIFI_VERSION_ARG does not match the version regex" >&2
        exit 1
      fi
    fi

    if check_java_installation "$JAVA_HOME"; then
        download_cmd="wget"
        download_threads_count=5

        # Selecting download command
        if ! command_exists aria2c; then
          echo "aria2c is not installed, wget will be used for downloads"
        else
          echo "aria2c is installed and will be used for downloads"
          download_cmd="aria2c -x${download_threads_count} --summary-interval=0"
        fi

        # Saving current work dir
        pushd -n $(pwd) > /dev/null
        # Creating temp work dir
        dir_path="$HOME/$(uuidgen)"
        mkdir ${dir_path} && cd ${dir_path}
        echo "temp working dir is $(pwd)"
        # Downloading and extracting NiFi, NiFi Registry, NiFi Toolkit
        echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi ${NIFI_VERSION_ARG}"
        eval "${download_cmd} https://archive.apache.org/dist/nifi/${NIFI_VERSION_ARG}/nifi-${NIFI_VERSION_ARG}-bin.zip"
        unzip -q nifi-${NIFI_VERSION_ARG}-bin.zip -d ${NIFI_INSTALL_PATH_ARG}/
        echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi Registry ${NIFI_VERSION_ARG}"
        eval "${download_cmd} https://archive.apache.org/dist/nifi/$NIFI_VERSION_ARG/nifi-registry-${NIFI_VERSION_ARG}-bin.zip"
        unzip -q nifi-registry-${NIFI_VERSION_ARG}-bin.zip -d ${NIFI_INSTALL_PATH_ARG}/
        echo_with_bold_cyan "❯❯❯  Downloading and extracting Apache NiFi Toolkit ${NIFI_VERSION_ARG}"
        eval "${download_cmd} https://archive.apache.org/dist/nifi/$NIFI_VERSION_ARG/nifi-toolkit-${NIFI_VERSION_ARG}-bin.zip"
        unzip -q nifi-toolkit-${NIFI_VERSION_ARG}-bin.zip -d ${NIFI_INSTALL_PATH_ARG}/
        # Removing temp dir
        cd ~ && rm -rf ${dir_path}
        # Updating envinroment variables
        echo_with_bold_cyan "❯❯❯  Adding envinroment variables"
        source ~/.profile
        # Removing existed NiFi environment variables
        remove_env_variable "NIFI_VERSION"
        remove_env_variable "NIFI_HOME"
        remove_env_variable "NIFI_REGISTRY_HOME"
        remove_env_variable "NIFI_TOOLKIT_HOME"
        remove_env_variable "NIFI_BOOTSTRAP_FILE"
        remove_env_variable "NIFI_PROPS_FILE"
        remove_env_variable "NIFI_REGISTRY_PROPS_FILE"
        remove_env_variable "NIFI_TOOLKIT_PROPS_FILE"
        remove_env_variable "NIFI_INPUT"
        remove_env_variable "NIFI_OUTPUT"

        printf "\n" >> ~/.profile
        # Adding new environment variables
        echo "export NIFI_VERSION=${NIFI_VERSION_ARG}" >> ~/.profile
        echo "export NIFI_HOME=${NIFI_INSTALL_PATH_ARG}/nifi-${NIFI_VERSION_ARG}" >> ~/.profile
        echo "export NIFI_REGISTRY_HOME=${NIFI_INSTALL_PATH_ARG}/nifi-registry-${NIFI_VERSION_ARG}" >> ~/.profile
        echo "export NIFI_TOOLKIT_HOME=${NIFI_INSTALL_PATH_ARG}/nifi-toolkit-${NIFI_VERSION_ARG}" >> ~/.profile
        echo "export NIFI_BOOTSTRAP_FILE=${NIFI_INSTALL_PATH_ARG}/nifi-${NIFI_VERSION_ARG}/bootstrap.conf" >> ~/.profile
        echo "export NIFI_PROPS_FILE=${NIFI_INSTALL_PATH_ARG}/nifi-${NIFI_VERSION_ARG}/conf/nifi.properties" >> ~/.profile
        echo "export NIFI_REGISTRY_PROPS_FILE=${NIFI_INSTALL_PATH_ARG}/nifi-registry-${NIFI_VERSION_ARG}/conf/nifi-registry.properties" >> ~/.profile
        echo "export NIFI_TOOLKIT_PROPS_FILE=${NIFI_INSTALL_PATH_ARG}/nifi-toolkit-${NIFI_VERSION_ARG}/conf/cli.properties" >> ~/.profile

        NIFI_INPUT="${NIFI_INSTALL_PATH_ARG}/nifi-${NIFI_VERSION_ARG}/input"
        NIFI_OUTPUT="${NIFI_INSTALL_PATH_ARG}/nifi-${NIFI_VERSION_ARG}/output"

        echo "export NIFI_INPUT=${NIFI_INPUT}" >> ~/.profile
        echo "export NIFI_OUTPUT=${NIFI_OUTPUT}" >> ~/.profile
        mkdir -p ${NIFI_INPUT} ${NIFI_OUTPUT}
        printf "\n" >> ~/.profile

        source ~/.profile

        # Updating aliases for commands (for case when NiFi and NiFi Registry are not installed as a service)
        echo_with_bold_cyan "❯❯❯  Adding aliases for commands"
        source ~/.bashrc
        # Removing existed NiFi aliases
        remove_alias "NIFI_START"
        remove_alias "NIFI_STOP"
        remove_alias "NIFI_RESTART"
        remove_alias "NIFI_STATUS"

        printf "\n" >> ~/.bashrc
        # Adding new NiFi aliases
        echo "alias NIFI_START=\"$NIFI_HOME/bin/nifi.sh start\"" >> ~/.bashrc
        echo "alias NIFI_STOP=\"$NIFI_HOME/bin/nifi.sh stop\"" >> ~/.bashrc
        echo "alias NIFI_RESTART=\"$NIFI_HOME/bin/nifi.sh restart\"" >> ~/.bashrc
        echo "alias NIFI_STATUS=\"$NIFI_HOME/bin/nifi.sh status\"" >> ~/.bashrc
        printf "\n" >> ~/.bashrc

        # Removing existed NiFi Registry aliases
        remove_alias "NIFI_REGISTRY_START"
        remove_alias "NIFI_REGISTRY_STOP"
        remove_alias "NIFI_REGISTRY_RESTART"
        remove_alias "NIFI_REGISTRY_STATUS"

        # Adding new NiFi Registry aliases
        echo "alias NIFI_REGISTRY_START=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh start\"" >> ~/.bashrc
        echo "alias NIFI_REGISTRY_STOP=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh stop\"" >> ~/.bashrc
        echo "alias NIFI_REGISTRY_RESTART=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh restart\"" >> ~/.bashrc
        echo "alias NIFI_REGISTRY_STATUS=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh status\"" >> ~/.bashrc
        printf "\n" >> ~/.bashrc

        source ~/.bashrc

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

        # Set sensitive key
        eval "$NIFI_HOME/bin/nifi.sh set-sensitive-properties-key ${nifi_sensitive_key} &> /dev/null"
        echo_with_italics "Updated setting 'nifi.sensitive.props.key' to value '${nifi_sensitive_key}'"


        if eval "$NIFI_HOME/bin/nifi.sh set-single-user-credentials $NIFI_LOGIN_ARG $NIFI_PASSWORD_ARG"; then
            max_timeout_sec=150
            # Start NiFi and wait
            if eval "NIFI_START"; then
                echo -n "Waiting for NiFi start ..."
                t=1
                nifi_web_interface_link=""
                while [[ $t -le $max_timeout_sec ]] && [[ -z "$nifi_web_interface_link" ]]
                do
                  nifi_web_interface_link=$(grep "Started Server on" "$NIFI_HOME/logs/nifi-app.log" 2>/dev/null | tail -1 | grep -Eo '(http|https)://[^/"]+/nifi')

                  if [[ -z "$nifi_web_interface_link" ]]; then
                    nifi_web_interface_link=$(grep -A1 "The UI is available at the following URLs" "$NIFI_HOME/logs/nifi-app.log" 2>/dev/null | tail -10 | grep -Eo '(http|https)://[^/"]+/nifi' | head -1)
                  fi

                  echo -n '.'
                  ((t=t+1))
                  sleep 1
                done
                printf "\n"
                if [ "$t" -le $max_timeout_sec ]; then
                    echo_with_bold_cyan "❯❯❯  NiFi started at ${nifi_web_interface_link}/nifi/"
                    nohup xdg-open "$nifi_web_interface_link" &> /dev/null &
                    # If NiFi started succesfully then start NiFi Registry
                    # Start NiFi Registry and wait
                    if eval "NIFI_REGISTRY_START"; then
                        echo -n "Waiting for NiFi Registry start ..."
                        k=1
                        nifi_web_interface_link=""
                        while [[ $t -le $max_timeout_sec ]] && [[ -z "$nifi_web_interface_link" ]]
                        do
                          nifi_web_interface_link=$(grep "Started Server on" "$NIFI_REGISTRY_HOME/logs/nifi-registry-app.log" 2>/dev/null | tail -1 | grep -Eo '(http|https)://[^/"]+/nifi-registry')
                          echo -n '.'
                          ((t=t+1))
                          sleep 1
                        done
                        printf "\n"
                        if [ "$t" -le $max_timeout_sec ]; then
                            echo_with_bold_cyan "❯❯❯  NiFi Registry started at ${nifi_web_interface_link}/nifi/"
                            nohup xdg-open "$nifi_web_interface_link" &> /dev/null &
                        else
                            echo_with_bold_red "ERROR, NiFi Registry not started (timeout exceeded)" >&2
                        fi
                    else
                        echo_with_bold_red "ERROR, NiFi Registry starting failed with exit code $?" >&2
                    fi
                else
                  echo_with_bold_red "ERROR, NiFi not started (timeout exceeded)" >&2
                fi
            else
                echo_with_bold_red "ERROR, NiFi starting failed with exit code $?" >&2
            fi
        else
            echo_with_bold_red "ERROR, NiFi setting single-user-credentials failed with exit code $?" >&2
        fi

        # Restoring saved working dir
        popd > /dev/null
        exec bash
    else
        echo_with_bold_red "Failed to check JAVA_HOME" >&2
        exit 1
    fi

else
    echo "This shell is not interactive"
    echo "For correct operation, please run the script as: bash -i $(basename "$0")"
    exit 1
fi
