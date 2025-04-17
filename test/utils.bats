#!/usr/bin/env bash

load "../lib/utils.bash"

@test "get_arch (x86_64) should return x86_64" {
    run get_arch
    [ "$status" -eq 0 ]
    [ "$output" = "x86_64" ]
}

@test "get_arch (aarch64) should return aarch64" {
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="aarch64"
    run get_arch
    [ "$status" -eq 0 ]
    [ "$output" = "aarch64" ]
}

@test "get_arch (arm64) should return arm64" {
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="arm64"
    run get_arch
    [ "$status" -eq 0 ]
    [ "$output" = "arm64" ]
}

@test "get_arch (invalid) should throw error" {
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="invalid"
    run get_arch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unsupported architecture: invalid" ]]
}

@test "get_os_name (invalid) should throw error" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="invalid"
    run get_os_name
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not supported OS: invalid" ]]
}

@test "get_os_name (ubuntu2204) should return os" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="Ubuntu"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="22.04"

    run get_os_name
    [ "$status" -eq 0 ]
    [ "$output" = "ubuntu2204" ]
}

@test "get_os_name (ubuntu1604) should return os" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="Ubuntu"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="16.04"

    run get_os_name
    [ "$status" -eq 0 ]
    [ "$output" = "ubuntu1604" ]
}

@test "get_os_name (amazon2) should return os" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="amzn"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2"

    run get_os_name
    [ "$status" -eq 0 ]
    [ "$output" = "amazon2" ]
}

@test "get_os_name (amazon2023) should return os" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="amzn"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2023"

    run get_os_name
    [ "$status" -eq 0 ]
    [ "$output" = "amazon2023" ]
}

@test "get_download_url (invalid|2|x86_64) should return error" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="invalid"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2"
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="x86_64"

    run get_download_url "100.6.1"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not supported OS: invalid" ]]
}

@test "get_download_url (Ubuntu|2204|invalid) should return error" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="ubuntu"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="22.04"
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="invalid"

    run get_download_url "100.6.1"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unsupported architecture: invalid" ]]
}

@test "get_download_url (amzn|2|x86_64) should return url" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="amzn"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2"
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="x86_64"

    run get_download_url "100.6.1"
    [ "$status" -eq 0 ]
    [ "$output" = "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-amazon2-x86_64-100.6.1.tgz" ]
}

@test "get_download_url (invalid) should return url" {
    ASDF_MONGODB_TOOLS_VERSION_URL="https://google.com"

    run get_download_url "100.6.1"
    [ "$status" -eq 1 ]
}

@test "list_all_versions (amzn|2|x86_64) should return url" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="amzn"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2"
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="x86_64"

    run list_all_versions
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "list_all_versions (invalid|2|x86_64) should return error" {
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_ID="invalid"
    ASDF_MONGODB_TOOLS_OVERWRITE_OS_VERSION="2"
    ASDF_MONGODB_TOOLS_OVERWRITE_ARCH="x86_64"

    run list_all_versions
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not supported OS: invalid" ]]
}
