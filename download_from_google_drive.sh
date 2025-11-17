#!/usr/bin/env bash

[ -n "$BASH_VERSION" ] || { echo "Please run this script with bash"; exit 1; }

download_from_gdrive() {
    local file_url="$1"
    local output_name="$2"
    local file_id
    file_id=$(echo "$file_url" | sed -n -E 's/.*\/d\/([a-zA-Z0-9_-]+).*/\1/p')
    if [[ -z "$file_id" ]]; then
        file_id=$(echo "$file_url" | sed -n -E 's/.*id=([a-zA-Z0-9_-]+).*/\1/p')
    fi
    if [[ -z "$file_id" ]]; then
        echo "Error: Could not extract file ID from URL"
        return 1
    fi
    echo "File ID: $file_id"
    local download_url="https://drive.google.com/uc?export=download&id=$file_id"
    echo "Starting download..."
    if command -v wget &> /dev/null; then
        wget --progress=bar:force --no-check-certificate -O "$output_name" "$download_url"
    elif command -v curl &> /dev/null; then
        curl -L -o "$output_name" "$download_url"
    else
        echo "Error: wget or curl not found. Please install one of them."
        return 1
    fi
    if [[ $? -eq 0 ]]; then
        echo "File successfully downloaded: $output_name"
    else
        echo "Error downloading file"
        return 1
    fi
}

download_large_file() {
    local file_url="$1"
    local output_name="$2"
    local file_id=$(echo "$file_url" | sed -n -E 's/.*\/d\/([a-zA-Z0-9_-]+).*/\1/p')
    if [[ -z "$file_id" ]]; then
        file_id=$(echo "$file_url" | sed -n -E 's/.*id=([a-zA-Z0-9_-]+).*/\1/p')
    fi
    if [[ -z "$file_id" ]]; then
        echo "Error: Could not extract file ID from URL"
        return 1
    fi
    echo "File ID: $file_id"
    local confirm_token=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate \
        "https://drive.google.com/uc?export=download&id=$file_id" -O- | \
        sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p')
    local download_url="https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=$file_id"
    echo "Starting large file download..."
    if command -v wget &> /dev/null; then
        wget --progress=bar:force --load-cookies /tmp/cookies.txt --no-check-certificate -O "$output_name" "$download_url"
        rm -f /tmp/cookies.txt
    elif command -v curl &> /dev/null; then
        echo "For large files, wget is recommended"
        return 1
    else
        echo "Error: wget or curl not found. Please install one of them."
        return 1
    fi
    if [[ $? -eq 0 ]]; then
        echo "File successfully downloaded: $output_name"
    else
        echo "Error downloading file"
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 [OPTIONS] <Google_Drive_URL> [output_filename]"
        echo ""
        echo "Examples:"
        echo "  $0 \"https://drive.google.com/file/d/1ABC123def456/view\""
        echo "  $0 \"https://drive.google.com/file/d/1ABC123def456/view\" myfile.zip"
        echo "  $0 -l \"https://drive.google.com/file/d/1ABC123def456/view\""
        echo "  $0 -l \"https://drive.google.com/file/d/1ABC123def456/view\" my_large_file.zip"
        echo ""
        echo "Options:"
        echo "  -l, --large    For downloading large files (for files larger than 100 MB)"
        exit 1
    fi
    local file_url=""
    local output_name=""
    local large_file=false
    local args=("$@")

    for (( i=0; i<${#args[@]}; i++ )); do
        case "${args[i]}" in
            -l|--large)
                large_file=true
                ;;
            -*)
                echo "Error: Unknown option ${args[i]}"
                exit 1
                ;;
            *)
                if [[ -z "$file_url" ]]; then
                    file_url="${args[i]}"
                elif [[ -z "$output_name" ]]; then
                    output_name="${args[i]}"
                else
                    echo "Error: Too many arguments"
                    exit 1
                fi
                ;;
        esac
    done
    if [[ -z "$file_url" ]]; then
        echo "Error: Google Drive URL is required"
        exit 1
    fi
    if [[ -z "$output_name" ]]; then
        output_name="downloaded_file_$(date +%Y%m%d_%H%M%S)"
    fi
    echo "URL: $file_url"
    echo "Output file: $output_name"
    echo ""
    if [[ "$large_file" == true ]]; then
        download_large_file "$file_url" "$output_name"
    else
        download_from_gdrive "$file_url" "$output_name"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
