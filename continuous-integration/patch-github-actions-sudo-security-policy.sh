#!/usr/bin/env bash
# Patch the sudo security policy so that the environment variables
# defined in the GitHub Actions CI environment would be inherited in
# processes run using sudo
#
# References:
#
# * Including other files from within sudoers | Sudoers Manual | Sudo
#   https://www.sudo.ws/docs/man/sudoers.man/#Including_other_files_from_within_sudoers
#
# Copyright 2023 林博仁(Buo-ren, Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects

# Configure the interpreter behavior to bail out during problematic
# situations
set \
    -o errexit \
    -o nounset

required_commands=(
    install
    realpath

    # For checking the validity of the sudoers file
    visudo
)
flag_dependency_check_failed=false
for required_command in "${required_commands[@]}"; do
    if ! command -v "${required_command}" >/dev/null; then
        flag_dependency_check_failed=true
        printf \
            'Error: Unable to locate the "%s" command in the command search PATHs.\n' \
            "${required_command}" \
            1>&2
    fi
done
if test "${flag_dependency_check_failed}" == true; then
    printf \
        'Error: Dependency check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

if test "${EUID}" -ne 0; then
    printf \
        'Error: This program is required to be run as the superuser(root).\n' \
        1>&2
    exit 1
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
    }
fi

ci_dir="${script_dir}"
sudoers_dropin_dir="${ci_dir}/sudoers.d"

sudoers_dropin_dir_system=/etc/sudoers.d
if ! test -e "${sudoers_dropin_dir_system}"; then
    printf \
        'Info: Creating the sudoers drop-in directory...\n'
    install_opts=(
        --directory
        --owner=root
        --group=root
        --mode=0755
        --verbose
    )
    if ! \
        install \
            "${install_opts[@]}" \
            "${sudoers_dropin_dir_system}"; then
        printf \
            'Error: Unable to create the sudoers drop-in directory.\n' \
            1>&2
        exit 2
    fi
fi

for dropin_file in "${sudoers_dropin_dir}/"*.sudoers; do
    dropin_filename="${dropin_file##*/}"

    printf \
        'Info: Validating the "%s" sudoers drop-in file...\n' \
        "${dropin_filename}"
    visudo_opts=(
        # Enable check-only mode
        --check

        # Specify an alternate sudoers file location
        --file="${dropin_file}"

        # NOTE: We don't use --quiet as it will also inhibit the syntax
        # error messages, dump the stdout stream instead
        #--quiet
    )
    if ! visudo "${visudo_opts[@]}" >/dev/null; then
        printf \
            'Error: Syntax validation failed for the "%s" sudoers drop-in file.\n' \
            "${dropin_filename}" \
            1>&2
        exit 2
    fi

    printf \
        'Info: Installing the "%s" sudoers drop-in file...\n' \
        "${dropin_filename}"

    # sudo will not accept filename with the period symbol in the
    # filename, strip the convenicence filename suffix
    dropin_filename_without_suffix="${dropin_filename%.sudoers}"

    installed_dropin_file="${sudoers_dropin_dir_system}/${dropin_filename_without_suffix}"
    install_opts=(
        --owner=root
        --group=root
        --mode=0644
        --verbose
    )
    if ! \
        install \
            "${install_opts[@]}" \
            "${dropin_file}" \
            "${installed_dropin_file}"; then
        printf \
            'Error: Unable to install the sudoers drop-in configuration file "%s".\n' \
            "${dropin_filename}" \
            1>&2
        exit 2
    fi
done

printf \
    'Info: Operation completed without errors.\n'
