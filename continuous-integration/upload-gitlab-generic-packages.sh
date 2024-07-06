#!/usr/bin/env sh
# Upload release packages as GitLab generic packages
#
# Copyright 2023 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects

set \
    -o errexit \
    -o nounset

if ! test CI_PROJECT_ID; then
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

for file in "${project_dir}/${CI_PROJECT_NAME}-"*; do
    if test "${file}" = "${project_dir}/${CI_PROJECT_NAME}-*"; then
        # No release packages are found, avoid missing file error
        break
    fi

    printf \
        'Info: Uploading the "%s" file to the GitLab generic packages registry...\n' \
        "${file}"

    filename="${file##*/}"
    package_registry_url="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${CI_PROJECT_NAME}/${release_version}/${filename}"

    if ! \
        curl \
            --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
            --upload-file "${file}" \
            "${package_registry_url}"; then
        printf \
            'Error: Unable to upload the "%s" file to the GitLab generic packages registry.\n' \
            "${file}" \
            1>&2
        exit 2
    fi
done

printf \
    'Info: Operation completed without errors.\n'
