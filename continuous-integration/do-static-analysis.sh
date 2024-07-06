#!/usr/bin/env bash
# Check potential problems in the project
# Copyright 2023 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects
set \
    -o errexit \
    -o nounset

script="${BASH_SOURCE[0]}"
if ! script="$(
    realpath \
        --strip \
        "${script}"
    )"; then
    printf \
        'Error: Unable to determine the absolute path of the program.\n' \
        1>&2
    exit 1
fi

script_dir="${script%/*}"
project_dir="$(dirname "${script_dir}")"
cache_dir="${project_dir}/.cache"

if ! test -e "${script_dir}/venv"; then
    printf \
        'Info: Initializing the Python virtual environment...\n'
    if ! python3 -m venv "${script_dir}/venv"; then
        printf \
            'Error: Unable to initialize the Python virtual environment.\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Activating the Python virtual environment...\n'
# Out of scope
# shellcheck source=/dev/null
if ! source "${script_dir}/venv/bin/activate"; then
    printf \
        'Error: Unable to activate the Python virtual environment.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Installing pre-commit...\n'
if ! pip show pre-commit &>/dev/null; then
    if ! pip install pre-commit; then
        printf \
            'Error: Unable to install pre-commit.\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Setting up the command search PATHs so that the installed shellcheck command can be located...\n'
PATH="${cache_dir}/shellcheck-stable:${PATH}"

printf \
    'Info: Running pre-commit...\n'
if ! \
    pre-commit run \
        --all-files \
        --color always; then
    printf \
        'Error: pre-commit check has failed, please verify.\n' \
        1>&2
    exit 3
fi

printf \
    'Info: Operation completed without errors.\n'
