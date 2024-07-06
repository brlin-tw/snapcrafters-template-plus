#!/usr/bin/env bash
# Create GitLab project release
#
# Copyright 2023 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects

set \
    -o errexit \
    -o nounset

if ! test -v CI_PROJECT_ID; then
    printf \
        'Error: This program should be run under a GitLab CI environment.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Determining release version...\n'
release_version="${CI_COMMIT_TAG#v}"

# bash - How to get script directory in POSIX sh? - Stack Overflow
# https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
project_dir="${script_dir%/*}"

printf \
    'Info: Determining release details...\n'
detailed_changes_file="${project_dir}/.detailed_changes"
if ! test -e "${detailed_changes_file}"; then
    printf \
        'Error: The detailed changes file "%s" does not exist.\n' \
        "${detailed_changes_file}" \
        1>&2
    exit 2
fi

release_cli_create_opts=(
    --name "${CI_PROJECT_TITLE} ${release_version}"
    --tag-name "${CI_COMMIT_TAG}"

    # WORKAROUND: Absolute path is not accepted as file input
    --description "${detailed_changes_file##*/}"
)

shopt -s nullglob
for file in "${project_dir}/${CI_PROJECT_NAME}-"*; do
    filename="${file##*/}"
    package_registry_url="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${CI_PROJECT_NAME}/${release_version}/${filename}"

    release_cli_create_opts+=(
        --assets-link "{\"name\": \"${filename}\", \"url\": \"${package_registry_url}\"}"
    )
done

printf \
    'Info: Creating the GitLab release...\n'
if ! \
    release-cli create \
        "${release_cli_create_opts[@]}"; then
    printf \
        'Error: Unable to create the GitLab release.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Operation completed without errors.\n'
