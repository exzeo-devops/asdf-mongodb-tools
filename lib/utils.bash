#!/usr/bin/env bash

set -euo pipefail

# Initialize Variables
ASDF_MONGODB_TOOLS_OVERWRITE_ARCH=""
ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID=""
ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION=""
ASDF_MONGODB_TOOLS_VERSION_URL="https://s3.amazonaws.com/downloads.mongodb.org/tools/db/full.json"

curl_opts=(-fsSL)

fail() {
    echo -e "$*" >&2
    exit 1
}

get_os_name() {
    local id=""
    local version_id=""

    if [[ "${ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID}" != "" ]]; then
        id="${ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID}"
    fi

    if [[ "${ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION}" != "" ]]; then
        version_id="${ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION}"
    fi

    if [[ -z "${id}" ]]; then
        if [ -f /etc/os-release ]; then
            id=$(grep -i '^ID=' /etc/os-release | cut -d= -f2)
        else
            id=$(uname -s | awk '{print tolower($0)}')
        fi
    fi

    if [[ -z "${version_id}" ]]; then
        if [ -f /etc/os-release ]; then
            version_id=$(grep -i '^VERSION_ID=' /etc/os-release | cut -d= -f2)
        fi
    fi

    # Validate
    if [[ -z "${id}" ]]; then
        fail "Unable to determine OS"
    fi

    # Format Version
    id=$(echo "$id" | tr -d '"' | tr '[:upper:]' '[:lower:]') # Remove quotes and lowercase
    version_id=$(echo "$version_id" | tr -d '"' | tr -d '.')  # Remove quotes and dots

    case "$id" in
    darwin) echo "macos" ;;
    ubuntu) echo "ubuntu${version_id}" ;;
    debian) echo "debian${version_id}" ;;
    rhel | redhat) echo "rhel${version_id}" ;;
    centos) echo "rhel${version_id}" ;;
    amzn | amazon) echo "amazon${version_id}" ;;
    *) fail "Not supported OS: $id" ;;
    esac
}

get_arch() {
    current_architecture="$(uname -m)"

    if [[ "${ASDF_MONGODB_TOOLS_OVERWRITE_ARCH}" != "" ]]; then
        current_architecture="${ASDF_MONGODB_TOOLS_OVERWRITE_ARCH}"
    fi

    case "$current_architecture" in
    x86_64 | amd64) current_architecture="x86_64" ;;
    armv7l | arm64) current_architecture="arm64" ;;
    aarch64) current_architecture="aarch64" ;;
    i386 | i686) current_architecture="x86" ;;
    *) fail "Unsupported architecture: $current_architecture" ;;
    esac

    echo "${current_architecture}"
}

sort_versions() {
    awk -F. '
    {
      orig = $0;
      n1 = $1; n2 = ($2 == "") ? 0 : $2;
      n3 = ($3 == "") ? 0 : $3;
      n4 = ($4 == "") ? 0 : $4;
      printf "%04d.%04d.%04d.%04d %s\n", n1, n2, n3, n4, orig;
    }
  ' | sort | awk '{print $2}' | paste -sd' ' -
}

list_all_versions() {
    name=$(get_os_name) || exit 1
    arch=$(get_arch) || exit 1

    # Get versions that have a download matching the OS
    versions=$(curl "${curl_opts[@]}" "$ASDF_MONGODB_TOOLS_VERSION_URL" | jq -r --arg name "$name" --arg arch "$arch" '.versions[] | select(.downloads[] | .name == $name and .arch == $arch) | .version ')

    echo "$versions"
}

get_download_url() {
    local version="$1"
    name=$(get_os_name) || exit 1
    arch=$(get_arch) || exit 1

    json=$(curl "${curl_opts[@]}" "$ASDF_MONGODB_TOOLS_VERSION_URL") || fail "Failed to fetch JSON from $ASDF_MONGODB_TOOLS_VERSION_URL"
    url=$(echo "$json" | jq -r --arg version "$version" --arg name "$name" --arg arch "$arch" '.versions[] | select(.version == $version) | .downloads[] | select(.name == $name and .arch == $arch) | .archive.url ') || fail "Failed to parse JSON for version=$version name=$name arch=$arch"

    echo "$url"
}

install_version() {
    local install_type=$1
    local version=$2
    local install_path=$3

    local download_url
    local filename
    local tmp_download_dir
    local tmp_download_path

    if [ "$install_type" != "version" ]; then
        fail "asdf-mongodb-tools supports release installs only"
    fi

    (
        # Get download url from mongodb
        download_url="$(get_download_url "$version")"

        # Check if the download URL is valid
        if [[ -z "$download_url" ]]; then
            fail "Unable to locate valid download url on $(get_os_name) | $(get_arch) for v$version"
        fi

        # Get filename from the URL
        filename="$(basename "${download_url}")"

        # Create a temporary directory in the system's temp directory
        tmp_download_dir="$(mktemp -d -t mongodb-tools_XXXXXX)"

        # Temporary download path with the filename
        tmp_download_path="${tmp_download_dir}/${filename}"

        echo "Downloading mongodb tools from ${download_url}"

        # Create the install path if it doesn't exist
        mkdir -p "${install_path}"

        # Download the file to the temporary directory
        curl -fLo "${tmp_download_path}" "${download_url}"

        # Extracting to temp folder
        tar -zxf "${tmp_download_path}" --directory "${tmp_download_dir}"

        # Move the binary folder to the install_path
        mv "${tmp_download_dir}/${filename%.*}/bin" "${install_path}/"

        echo "asdf-mongodb-tools v$version installation was successful!"
    ) || (
        # Cleanup
        rm -rf "${install_path}"
        fail "asdf-mongodb-tools v$version installation failed!"
    )
}
