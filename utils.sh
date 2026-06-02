#!/bin/bash

source './bash_color.sh'

#--------------------------------------------------------------------+
# Color output functions
#--------------------------------------------------------------------+
echo_with_bold() { echo -e "${BLD}$1${DEF}"; }
echo_with_italics() { echo -e "${CUR}$1${DEF}"; }
echo_with_bold_cyan() { echo -e "${CYN}${BLD}$1${DEF}"; }
echo_with_bold_red() { echo -e "${RED}${BLD}$1${DEF}"; }
echo_with_bold_green() { echo -e "${GRN}${BLD}$1${DEF}"; }
echo_with_bold_yellow() { echo -e "${YLW}${BLD}$1${DEF}"; }

#--------------------------------------------------------------------+
# Logging functions
#--------------------------------------------------------------------+
log() { echo "$(date "+%Y-%m-%d %H:%M:%S") $1"; }
log_info() { log "INFO: $1"; }
log_error() { log "ERROR: $1"; exit 1; }
log_warn() { echo_with_bold_yellow "WARN: $1"; }

#--------------------------------------------------------------------+
# File property manipulation
#--------------------------------------------------------------------+
add_or_update_property() {
    local file="$1"
    local key="$2"
    local value="$3"
    local separator="${4:-=}"

    # check file exist
    if [[ ! -f "$file" ]]; then
        echo_with_bold_red "Error: File '$file' does not exist" >&2
        return 1
    fi

    # escape value for sed
    local escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')

    # search for an active (not commented) line
    if grep -q "^${key}${separator}.*" "$file"; then
        # active line exists - repacing
        sed -i "s/^\(${key}${separator}\)[^#]*\(.*\)/\1${escaped_value}\2/" "$file"
        echo_with_italics "Updated active ${key}${separator}${value}"

    # search for a commented line (with a # at the beginning, spaces are possible)
    elif grep -q "^[[:space:]]*#.*${key}${separator}" "$file"; then
        # uncommenting
        sed -i "s/^[[:space:]]*#\(.*${key}${separator}\)[^#]*\(.*\)/\1${escaped_value}\2/" "$file"
        echo_with_italics "Uncommented and updated ${key}${separator}${value}"
    else
        # property is missing - add to the end
        echo "${key}${separator}${value}" >> "$file"
        echo_with_italics "Added ${key}${separator}${value}"
    fi
}

update_multiple_properties() {
    local file="$1"
    shift
    local pairs=("$@")
    # expecting an array of "key=value" pairs
    for pair in "${pairs[@]}"; do
        local key="${pair%%=*}"
        local value="${pair#*=}"
        add_or_update_property "$file" "$key" "$value"
    done
}

remove_property() {
    local file="$1"
    local key="$2"
    local separator="${3:-=}"
    # by default the line will be commented out, you can pass "delete" to delete
    local comment="${4:-#}"

    if [[ ! -f "$file" ]]; then
        echo_with_bold_red "Error: File '$file' does not exist" >&2
        return 1
    fi

    if [[ "$comment" == "delete" ]]; then
        sed -i "/^${key}${separator}.*/d" "$file"
        echo_with_italics "Removed ${key} from ${file}"
    else
        sed -i "s/^${key}${separator}.*/#&/" "$file"
        echo_with_italics "Commented ${key} in ${file}"
    fi
}

get_property() {
    local file="$1"
    local key="$2"
    local separator="${3:-=}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local value=$(grep "^${key}${separator}" "$file" | head -1 | cut -d"$separator" -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -n "$value" ]]; then
        GET_PROPERTY_RESULT="$value"
        return 0
    fi

    return 1
}

property_exists() {
    local file="$1"
    local key="$2"
    local separator="${3:-=}"

    grep -q "^[#]*\s*${key}${separator}.*" "$file" 2>/dev/null
}

uncomment_property() {
    local file="$1"
    local key="$2"
    local separator="${3:-=}"

    if [[ ! -f "$file" ]]; then
        echo_with_bold_red "Error: File '$file' does not exist" >&2
        return 1
    fi

    sed -i "s/^#\s*\(${key}${separator}.*\)/\1/" "$file"
    echo_with_italics "Uncommented ${key} in ${file}"
}

#--------------------------------------------------------------------+
# Environment and alias management
#--------------------------------------------------------------------+
remove_env_variable() {
    local var_name="$1"
    local file="${2:-~/.profile}"
    file="${file/#\~/$HOME}"

    if [[ -v "${var_name}" || -n "${!var_name+x}" ]]; then
        sed -i "/^export ${var_name}=/d" "$file"
        sed -i "/^export ${var_name}\$/d" "$file"
    fi
}

add_env_variable() {
    local var_name="$1"
    local var_value="$2"
    local file="${3:-~/.profile}"
    file="${file/#\~/$HOME}"
    # remove old record with env if exists
    sed -i "/^export ${var_name}=/d" "$file"
    # add new record with env
    echo "export ${var_name}=${var_value}" >> "$file"
    echo_with_italics "Added env: ${var_name}=${var_value} to ${file}"
}

is_alias() {
    [[ "$(type -t "$1")" = "alias" ]]
}

remove_alias() {
    local alias_name="$1"
    local target_file="${2:-~/.bashrc}"
    target_file="${target_file/#\~/$HOME}"

    # check alias existing in current session
    if ! is_alias "$alias_name"; then
        return 1
    fi

    echo_with_italics "Removing alias '${alias_name}' from ${target_file}"

    if sed -i "/^alias ${alias_name}=/d" "${target_file}"; then
        echo_with_italics "Successfully removed alias '${alias_name}'"
        unalias "$alias_name" 2>/dev/null || true
        return 0
    else
        echo_with_bold_red "Failed to remove alias '${alias_name}'" >&2
        return 1
    fi
}

add_alias() {
    local alias_name="$1"
    local alias_command="$2"
    local target_file="${3:-~/.bashrc}"
    target_file="${target_file/#\~/$HOME}"

    # add alias to file
    echo "alias ${alias_name}=\"${alias_command}\"" >> "$target_file"
    echo_with_italics "Added alias: ${alias_name} to ${target_file}"

    # add alias for current session
    eval "alias ${alias_name}=\"${alias_command}\""
}

#--------------------------------------------------------------------+
# System and command utilities
#--------------------------------------------------------------------+
command_exists() {
    command -v "${1}" > /dev/null 2>&1
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

generate_random_string() {
    local length="$1"
    openssl rand -base64 "$((length * 3 / 4 + 1))" | tr -dc A-Za-z0-9_ | head -c "$length"
}

download_file() {
    local url="$1"
    local output_dir="$2"
    local threads="${3:-5}"

    if command_exists aria2c; then
        aria2c -x "$threads" --summary-interval=0 "$url" -d "$output_dir"
    else
        wget "$url" -P "$output_dir"
    fi
}

#--------------------------------------------------------------------+
# Interactive shell check
#--------------------------------------------------------------------+
require_interactive_shell() {
    if [[ $- != *i* ]]; then
        echo "This shell is not interactive" >&2
        echo "For correct operation, please run the script as: bash -i $(basename "$0")" >&2
        exit 1
    fi
}

require_bash() {
    [ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }
}

#--------------------------------------------------------------------+
# Version validation
#--------------------------------------------------------------------+
validate_version() {
    local version="$1"
    local version_regex="^[0-9]+\.[0-9]+\.[0-9]+$"

    if [[ "$version" =~ $version_regex ]]; then
        return 0
    else
        echo_with_bold_red "ERROR: Version '$version' does not match format X.Y.Z" >&2
        return 1
    fi
}

get_latest_nifi_version() {
    wget -q -O- -T10 https://nifi.apache.org/download.html | \
        grep -oE "(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)" | \
        head -n1
}
