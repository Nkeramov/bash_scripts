#!/bin/bash

[ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }


remove_env_variable() {
  local var_name="$1"
  local file=${2:-~/.profile}
  if [[ -v "${var_name}" || -n "${!var_name+x}" ]]; then
    sed -i "/^export ${var_name}=/d" "$file"
    sed -i "/^export ${var_name}\$/d" "$file"
  fi
}


get_real_path() {
    local path="$1"
    if [ -z "$path" ]; then
        return 1
    fi
    if command -v readlink > /dev/null 2>&1; then
        local real_path
        if real_path=$(readlink -f "$path" 2>/dev/null); then
            GET_REAL_PATH_RESULT="$real_path"
            return 0
        fi
    fi
    if [ -L "$path" ]; then
        local link_target
        link_target=$(ls -l "$path" | awk '{print $NF}')
        if [ "${link_target:0:1}" = "/" ]; then
            GET_REAL_PATH_RESULT="$link_target"
        else
            GET_REAL_PATH_RESULT="$(dirname "$path")/$link_target"
        fi
    else
        GET_REAL_PATH_RESULT="$path"
    fi
    return 0
}


check_java_installation() {
    echo "Checking Java installation..." >&2
    if [ -z "$JAVA_HOME" ]; then
        echo "Error: JAVA_HOME environment variable is not set" >&2
        return 1
    fi

    if ! get_real_path "$JAVA_HOME"; then
        echo "Error: Failed to resolve JAVA_HOME path: $JAVA_HOME" >&2
        return 1
    fi
    local resolved_java_home="$GET_REAL_PATH_RESULT"

    if [ ! -d "$resolved_java_home" ]; then
        echo "Error: JAVA_HOME directory does not exist: $resolved_java_home" >&2
        return 1
    fi

    local java_cmd="$resolved_java_home/bin/java"

    if get_real_path "$java_cmd"; then
        local resolved_java_cmd="$GET_REAL_PATH_RESULT"
        if [ ! -x "$resolved_java_cmd" ]; then
            echo "Error: Java executable not found or not executable: $resolved_java_cmd" >&2
            return 1
        fi
        java_cmd="$resolved_java_cmd"
    else
        if [ ! -x "$java_cmd" ]; then
            echo "Error: Java executable not found or not executable: $java_cmd" >&2
            return 1
        fi
    fi

    local javac_cmd="$resolved_java_home/bin/javac"

    if get_real_path "$javac_cmd"; then
        local resolved_javac_cmd="$GET_REAL_PATH_RESULT"
        if [ ! -x "$resolved_javac_cmd" ]; then
            echo "Warning: javac not found - this might be a JRE instead of JDK" >&2
        fi
    else
        if [ ! -x "$javac_cmd" ]; then
            echo "Warning: javac not found - this might be a JRE instead of JDK" >&2
        fi
    fi

    local java_version=$("$java_cmd" -version 2>&1 | awk -F '"' '/version/ {print $2}')

    if [ -z "$java_version" ]; then
        echo "Error: Failed to get Java version" >&2
        return 1
    fi

    echo "Java validation successful: version $java_version, JAVA_HOME=$resolved_java_home" >&2
    return 0
}


find_java_installation() {
    local java_cmd=""
    local java_home=""

    if type -p java > /dev/null 2>&1; then
        echo "Found java executable in PATH" >&2
        java_cmd=$(which java)

        if get_real_path "$java_cmd" && [ -n "$GET_REAL_PATH_RESULT" ]; then
            local java_cmd_real="$GET_REAL_PATH_RESULT"
            local java_bin_dir=$(dirname "$java_cmd_real")
            if [ "$(basename "$java_bin_dir")" = "bin" ]; then
                java_home=$(dirname "$java_bin_dir")
                echo "Derived JAVA_HOME from java executable: $java_home" >&2
            fi
        fi
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
        echo "Found java executable in JAVA_HOME" >&2

        if get_real_path "$JAVA_HOME" && [ -n "$GET_REAL_PATH_RESULT" ]; then
            java_home="$GET_REAL_PATH_RESULT"
            echo "Resolved JAVA_HOME to: $java_home" >&2
        else
            java_home="$JAVA_HOME"
        fi
        java_cmd="$java_home/bin/java"
    else
        echo "The JAVA_HOME environment variable is not defined correctly" >&2
        echo "JAVA_HOME should point to a JDK not a JRE" >&2
        echo "Also, no java executable found in PATH" >&2
        return 1
    fi

    if [[ "$java_cmd" ]]; then
        local java_version=$("$java_cmd" -version 2>&1 | awk -F '"' '/version/ {print $2}')

        local java_cmd_real_display="$java_cmd"
        if get_real_path "$java_cmd" && [ -n "$GET_REAL_PATH_RESULT" ]; then
            java_cmd_real_display="$GET_REAL_PATH_RESULT"
        fi

        echo "Java executable: $java_cmd_real_display" >&2
        echo "Java version: $java_version" >&2
        if [ -n "$java_home" ]; then
            echo "JAVA_HOME: $java_home" >&2
        fi

        JAVA_CMD="$java_cmd"
        JAVA_HOME="$java_home"
        JAVA_VERSION="$java_version"
    else
        return 1
    fi
}


if [[ $- == *i* ]]; then
    echo "This shell is interactive"
    java_check=$(check_java_installation "$JAVA_HOME")
    if [ -n "$java_check" ]; then
        echo "$java_check"
    else
        echo "Failed to check JAVA_HOME. Trying to find java installation"
        if find_java_installation; then
            echo "Java successfully found and configured" >&2
            echo "Do you want to save JAVA_HOME to ~/.profile? (y/n)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                remove_env_variable "JAVA_HOME" ~/.profile
                echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.profile
                echo "JAVA_HOME has been saved to ~/.profile"
                echo "Please run 'source ~/.profile' or restart your terminal to apply changes"
            fi
        else
            exit 1
        fi
    fi
else
    echo "This shell is not interactive"
    echo "For correct operation, please run the script as: bash -i $(basename "$0")"
    exit 1
fi
