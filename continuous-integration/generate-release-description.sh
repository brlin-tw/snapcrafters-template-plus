#!/usr/bin/env bash
# Generate release description text to explain the changes between the
# previous release
#
# Copyright 2023 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0 OR LicenseRef-Apache-2.0-If-Not-Used-In-Template-Projects

set \
    -o errexit \
    -o nounset

if ! test -v CI; then
    printf \
        'Error: This program should be run under a GitLab CI/GitHub Actions environment.\n' \
        1>&2
    exit 1
fi

# bash - How to get script directory in POSIX sh? - Stack Overflow
# https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
project_dir="${script_dir%/*}"

printf 'Info: Querying the list of the release tag(s)...\n'
if ! git_tag_list="$(git tag --list 'v*')"; then
    printf \
        'Error: Unable to query the list of the release tag(s).\n' \
        1>&2
    exit 2
fi

printf 'Info: Counting the release tags...\n'
if ! git_tag_count="$(wc -l <<<"${git_tag_list}")"; then
    printf \
        'Error: Unable to count the release tags.\n' \
        1>&2
    exit 2
fi

detailed_changes_markup="## Detailed changes"$'\n\n'

if test -v CI_COMMIT_TAG; then
    release_tag="${CI_COMMIT_TAG}"
fi

if test "${git_tag_count}" -eq 1; then
    printf \
        'Info: Only one release tag was detected, generating the release description text from the very beginning to the "%s" release tag...\n' \
        "${release_tag}"
    if ! detailed_changes_markup+="$(
        git log \
            "${git_log_opts[@]}" \
            "${release_tag}"
        )"; then
        printf \
            'Error: Unable to generate the release description text from Git.\n' \
            1>&2
        exit 2
    fi
else
    printf \
        'Info: Multiple release tags were detected, determining the previous release tag...\n'
    printf \
        'Info: Version-sorting the release tag list...\n'
    if ! sorted_git_tag_list="$(
        sort \
            -V \
            <<<"${git_tag_list}"
        )"; then
        printf \
            'Error: Unable to version-sort the release tag list.\n' \
            1>&2
        exit 2
    fi

    printf \
        'Info: Filtering out the two latest release tags from the release tag list...\n'
    if ! latest_two_git_tags="$(
        tail \
            -n 2 \
            <<<"${sorted_git_tag_list}"
        )"; then
        printf \
            'Error: Unable to filter out the two latest release tags from the release tag list.\n' \
            1>&2
        exit 2
    fi

    printf \
        'Info: Filtering out the previous release tag from the two latest release tags...\n'
    if ! previous_git_tag="$(
        head \
            -n 1 \
            <<<"${latest_two_git_tags}"
        )"; then
        printf \
            'Error: Unable to filter out the previous release tag from the two latest release tags.\n' \
            1>&2
        exit 2
    fi

    printf \
        'Info: Generating the release description text from the previous release tag(%s) to the current release tag(%s)...\n' \
            "${previous_git_tag}" \
            "${release_tag}" \
            1>&2
    git_log_opts=(
        --format='format:* %s (%h) - %an'
    )
    if ! detailed_changes_markup+="$(
        git log \
            "${git_log_opts[@]}" \
            "${previous_git_tag}..${release_tag}"
        )"; then
        printf \
            'Error: Unable to generate the release description text from the previous release tag(%s) to the current release tag(%s).\n' \
            "${previous_git_tag}" \
            "${release_tag}" \
            1>&2
        exit 2
    fi
fi

detailed_changes_file="${project_dir}/.detailed_changes"
printf \
    'Info: Writing the detailed changes markup to the "%s" file...\n' \
    "${detailed_changes_file}"
if ! \
    printf \
        '%s\n' \
        "${detailed_changes_markup}" \
        | tee "${detailed_changes_file}"; then
    printf \
        'Error: Unable to write the detailed changes markup to the "%s" file.\n' \
        "${detailed_changes_file}" \
        1>&2
    exit 2
fi

printf \
    'Info: Operation completed without errors.\n'
