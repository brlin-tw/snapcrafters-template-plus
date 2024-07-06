#!/usr/bin/env bash
# System dependency installation logic for the static analysis program
#
# Copyright 2023 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects
set \
    -o errexit \
    -o nounset

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

trap_exit(){
    if test -v temp_dir \
        && test -e "${temp_dir}"; then
        rm -rf "${temp_dir}"
    fi
}
trap trap_exit EXIT

if test "${EUID}" -ne 0; then
    printf \
        'Error: This program should be run as the superuser(root) user.\n' \
        1>&2
    exit 1
fi

project_dir="$(dirname "${script_dir}")"
cache_dir="${project_dir}/.cache"

if ! test -e "${cache_dir}"; then
    install_opts=(
        --directory
    )
    if test -v SUDO_USER; then
        # Configure same user as the running environment to avoid access
        # problems afterwards
        install_opts+=(
            --owner "${SUDO_USER}"
            --group "${SUDO_GID}"
        )
    fi
    if ! install "${install_opts[@]}" "${cache_dir}"; then
        printf \
            'Error: Unable to create the cache directory.\n' \
            1>&2
        exit 2
    fi
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

base_runtime_dependency_pkgs=(
    wget
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

if ! test -v CI; then
    printf \
        'Info: Detecting local region code...\n'
    wget_opts=(
        # Output to the standard output device
        --output-document=-

        # Don't output debug messages
        --quiet
    )
    if ip_reverse_lookup_service_response="$(
            wget \
                "${wget_opts[@]}" \
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
    # For matching the ShellCheck version string
    grep

    git

    python3-minimal
    python3-pip
    python3-venv

    # For extracting prebuilt ShellCheck software archive
    tar
    xz-utils
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

shellcheck_dir="${cache_dir}/shellcheck-stable"

if ! test -e "${shellcheck_dir}/shellcheck"; then
    printf \
        "Info: Determining the host machine's hardware architecture...\\n"
    if ! arch="$(arch)"; then
        printf \
            "Error: Unable to determine the host machine's hardware architecture.\\n" \
            1>&2
        exit 1
    fi

    printf \
        'Info: Checking ShellCheck architecure availability...\n'
    case "${arch}" in
        x86_64|armv6hf|aarch64)
            # Assuming the ShellCheck architecture is the same, which
            # is probably incorrect...
            shellcheck_arch="${arch}"
        ;;
        *)
            printf \
                'Error: Unsupported ShellCheck architecture "%s".\n' \
                "${arch}" \
                1>&2
            exit 1
        ;;
    esac

    printf \
        'Info: Determining the ShellCheck prebuilt archive details...\n'
    prebuilt_shellcheck_archive_url="https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.${shellcheck_arch}.tar.xz"
    prebuilt_shellcheck_archive_filename="${prebuilt_shellcheck_archive_url##*/}"

    printf \
        'Info: Creating the temporary directory for storing downloaded files...\n'
    mktemp_opts=(
        --directory
        --tmpdir
    )
    if ! temp_dir="$(
        mktemp \
            "${mktemp_opts[@]}" \
            "${script_name}.XXXXXX"
        )"; then
        printf \
            'Error: Unable to create the temporary directory for storing downloaded files.\n' \
            1>&2
        exit 2
    fi

    printf \
        'Info: Downloading the prebuilt ShellCheck software archive...\n'
    downloaded_prebuilt_shellcheck_archive="${temp_dir}/${prebuilt_shellcheck_archive_filename}"
    wget_opts=(
        --output-document "${downloaded_prebuilt_shellcheck_archive}"
    )
    if ! \
        wget \
            "${wget_opts[@]}" \
            "${prebuilt_shellcheck_archive_url}"; then
        printf \
            'Error: Unable to download the prebuilt ShellCheck software archive...\n' \
            1>&2
        exit 2
    fi

    printf \
        'Info: Extracting the prebuilt ShellCheck software archive...\n'
    tar_opts=(
        --extract
        --verbose
        --directory="${cache_dir}"
        --file="${downloaded_prebuilt_shellcheck_archive}"
    )
    if test -v SUDO_USER; then
        # Configure same user as the running environment to avoid access
        # problems afterwards
        tar_opts+=(
            --owner="${SUDO_USER}"
            --group="${SUDO_GID}"
        )
    fi
    if ! tar "${tar_opts[@]}"; then
        printf \
            'Error: Unable to extract the prebuilt ShellCheck software archive.\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Setting up the command search PATHs so that the locally installed shellcheck command can be located...\n'
PATH="${shellcheck_dir}:${PATH}"

printf \
    'Info: Querying the ShellCheck version...\n'
if ! shellcheck_version_raw="$(shellcheck --version)"; then
    printf \
        'Error: Unable to query the ShellCheck version.\n' \
        1>&2
    exit 2
fi

grep_opts=(
    --perl-regexp
    --only-matching
)
if ! shellcheck_version="$(
    grep \
        "${grep_opts[@]}" \
        '(?<=version: ).*' \
        <<<"${shellcheck_version_raw}"
    )"; then
    printf \
        'Error: Unable to parse out the ShellCheck version string.\n' \
        1>&2
fi

printf \
    'Info: ShellCheck version is "%s".\n' \
    "${shellcheck_version}"

printf \
    'Info: Operation completed without errors.\n'
