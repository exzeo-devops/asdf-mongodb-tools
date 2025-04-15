#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for <YOUR TOOL>.
TOOL_NAME="mongodb-tools"

MONGODB_VERSION_URL="https://s3.amazonaws.com/downloads.mongodb.org/tools/db/full.json"

curl_opts=(-fsSL)

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

get_os_name() {
  local id version_id codename

  if command -v lsb_release &>/dev/null; then
    id=$(lsb_release -si | awk '{print tolower($0)}')
    version_id=$(lsb_release -sr | tr -d '.')
  elif [ -f /etc/os-release ]; then
    id=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    version_id=$(grep -i '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr -d '.')
  elif [ -f /etc/redhat-release ]; then
    id=$(awk '{print tolower($1)}' /etc/redhat-release)
    version_id=$(awk '{print $3}' /etc/redhat-release | tr -d '.')
  else
    id=$(uname -s | awk '{print tolower($0)}')
    version_id=""
  fi

  case "$id" in
	  darwin)
			echo "macos"
			;;
    ubuntu)
      echo "ubuntu${version_id}"
      ;;
    debian)
      echo "debian${version_id}"
      ;;
    rhel|redhat)
      echo "rhel${version_id}"
      ;;
    centos)
      echo "rhel${version_id}"  # Mongo tools usually map centos under rhel
      ;;
    amzn|amazon)
      echo "amazon${version_id}"
      ;;
    *)
      fail "Not supported OS: $id"
      ;;
  esac
}

get_arch() {
  arch=$(uname -m)

  case "$arch" in
    x86_64 | amd64)
      echo "x86_64"
      ;;
    aarch64 | arm64)
      echo "arm64"
      ;;
    armv7l)
      echo "armv7"
      ;;
    i386 | i686)
      echo "x86"
      ;;
    *)
      echo "$arch"
      ;;
  esac
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
  name=$(get_os_name)
  arch=$(get_arch)

	# Get versions that have a download matching the OS
  versions=$(curl "${curl_opts[@]}" "$MONGODB_VERSION_URL" | jq -r --arg name "$name" --arg arch "$arch" '.versions[] | select(.downloads[] | .name == $name and .arch == $arch) | .version ')

  echo "$versions"
}

get_download_url() {
  local version="$1"
  name=$(get_os_name)
  arch=$(get_arch)

  url=$(curl -s $MONGODB_VERSION_URL |
    jq -r --arg version "$version" --arg name "$name" --arg arch "$arch" '
      .versions[]
      | select(.version == $version)
      | .downloads[]
      | select(.name == $name and .arch == $arch)
      | .archive.url
    ')

  echo "$url"
}

install_version() {
  local install_type=$1
  local version=$2
  local install_path=$3

	local bin_install_path="$install_path/bin"
	local download_url=$(get_download_url "$version")
  local filename=$(basename $download_url)

  local tmp_download_dir=$(mktemp -d -t mongodb-tools_XXXXXX)
  local download_path="$tmp_download_dir/$filename"

  echo "Downloading mongodb tools from ${download_url} to ${download_path}"

  # capture error message from curl in memory
  curl --retry 10 --retry-delay 2 -fLo $download_path $download_url 2> >(tee /tmp/curl_error >&2)
  ERROR=$(</tmp/curl_error)

  # retry with http1.1 if http2 error
  if [[ $ERROR == *"HTTP/2 stream 0 was not closed cleanly"* ]]; then
    echo $ERROR
    echo "Retrying with --http1.1"
    curl --http1.1 --retry 10 --retry-delay 2 -fLo $download_path $download_url
  fi

  if [ $? -ne 0 ]; then
    echo $ERROR
    echo "Failed to download mongodb tools from ${download_url}"
    exit 1
  fi

  echo "Creating bin directory"
  mkdir -p "${bin_install_path}"

  echo "Copying binary"
  tar -zxf ${download_path} --directory $tmp_download_dir
  cp $tmp_download_dir/${filename%.*}/bin ${bin_install_path}
}
