#!/usr/bin/env bash
# Install system dependencies required for generating the project
# build artifacts
#
# Copyright 2023 林博仁(Buo-ren, Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects

set \
    -o errexit \
    -o errtrace \
    -o nounset

required_commands=(
    realpath
)
flag_dependency_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_dependency_check_failed=true
        printf \
            'Error: Unable to locate the "%s" command in the command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_dependency_check_failed}" == true; then
    printf \
        'Error: Dependency check failed, please check your installation.\n' \
        1>&2
fi

if test -v BASH_SOURCE; then
    # Convenience variables
    # shellcheck disable=SC2034
    {
        script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
        )"
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
    }
fi

if test "${EUID}" -ne 0; then
    printf \
        'Error: This program should be run as the superuser(root) user.\n' \
        1>&2
    exit 1
fi

apt_archive_cache_mtime_epoch="$(
    stat \
        --format=%Y \
        /var/cache/apt/archives
)"
current_time_epoch="$(
    date +%s
)"
if test "$((current_time_epoch - apt_archive_cache_mtime_epoch))" -ge 86400; then
    printf \
        'Info: Refreshing the APT local package cache...\n'
    if ! apt-get update; then
        printf \
            'Error: Unable to refresh the APT local package cache.\n' \
            1>&2
    fi
fi

# Silence warnings regarding unavailable debconf frontends
export DEBIAN_FRONTEND=noninteractive

if ! test -v CI; then
    base_runtime_dependency_pkgs=(
        curl
        grep
        sed
    )
    if ! dpkg -s "${base_runtime_dependency_pkgs[@]}" &>/dev/null; then
        printf \
            'Info: Installing base runtime dependency packages...\n'
        if ! \
            apt-get install \
                -y \
                "${base_runtime_dependency_pkgs[@]}"; then
            printf \
                'Error: Unable to install the base runtime dependency packages.\n' \
                1>&2
            exit 2
        fi
    fi

    printf \
        'Info: Detecting local region code...\n'
    curl_opts=(
        # Don't output debug messages
        --silent
        --show-error
    )
    if ip_reverse_lookup_service_response="$(
            curl \
                "${curl_opts[@]}" \
                https://ipinfo.io/json
        )"; then
        grep_opts=(
            --perl-regexp
            --only-matching
        )
        if ! region_code="$(
            grep \
                "${grep_opts[@]}" \
                '(?<="country": ")[[:alpha:]]+' \
                <<<"${ip_reverse_lookup_service_response}"
            )"; then
            printf \
                'Warning: Unable to query the local region code, falling back to default.\n' \
                1>&2
            region_code=
        else
            printf \
                'Info: Local region code determined to be "%s"\n' \
                "${region_code}"
        fi
    else
        printf \
            'Warning: Unable to detect the local region code(IP address reverse lookup service not available), falling back to default.\n' \
            1>&2
        region_code=
    fi

    if test -n "${region_code}"; then
        # The returned region code is capitalized, fixing it.
        region_code="${region_code,,*}"

        printf \
            'Info: Checking whether the local Ubuntu archive mirror exists...\n'
        if ! \
            getent hosts \
                "${region_code}.archive.ubuntu.com" \
                >/dev/null; then
            printf \
                "Warning: The local Ubuntu archive mirror doesn't seem to exist, falling back to default...\\n"
            region_code=
        fi
    fi

    if test -n "${region_code}" \
        && ! grep -q "${region_code}.archive.u" /etc/apt/sources.list; then
        printf \
            'Info: Switching to use the local APT software repository mirror...\n'
        if ! \
            sed \
                --in-place \
                "s@//archive.u@//${region_code}.archive.u@g" \
                /etc/apt/sources.list; then
            printf \
                'Error: Unable to switch to use the local APT software repository mirror.\n' \
                1>&2
            exit 2
        fi

        printf \
            'Info: Refreshing the local APT software archive cache...\n'
        if ! apt-get update; then
            printf \
                'Error: Unable to refresh the local APT software archive cache.\n' \
                1>&2
            exit 2
        fi
    fi
fi

runtime_dependency_pkgs=(
    # project archive compression dependencies
    #bzip2
    gzip
    #xz

    git

    python3-minimal
    python3-pip
    python3-venv
)
if ! dpkg -s "${runtime_dependency_pkgs[@]}" &>/dev/null; then
    printf \
        'Info: Installing the runtime dependency packages...\n'
    if ! apt-get install -y \
        "${runtime_dependency_pkgs[@]}"; then
        printf \
            'Error: Unable to install the runtime dependency packages.\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Operation completed without errors.\n'
