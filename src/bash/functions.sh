#!/usr/bin/env bash

# This file contains functions which are sourced by the release.sh
# script. You should not execute this file, you should _source_ it,
# e.g. `> source functions.sh` or `> . functions.sh` (`.` is an alias
# for `source` in bash).

# If the environment variable `FAKE_HOME` is unset, create a temporary
# directory with mktemp(1p) and set `FAKE_HOME` to that value and copy
# SBT related cache directories into `FAKE_HOME`.
#
# If `FAKE_HOME` is unset then this function also registers a trap
# (see bash(1)) to cleanup (rm -rf) the directory on termination of
# the script. BE CAREFUL HERE.
#
# If `FAKE_HOME` is already set when this function is invoked, no trap
# is registered.
#
# Whether or not `FAKE_HOME` is set at the time of invocation this
# function will also reset the `HOME` environment variable to the
# value of `FAKE_HOME` and add `-Duser.home=${FAKE_HOME}` to the
# `JAVA_TOOL_OPTIONS` environment variable.
setup_fake_home() {
    if [ -z "$FAKE_HOME" ]
    then
        declare -x FAKE_HOME
        FAKE_HOME="$(mktemp -d)"
        echo "FAKE_HOME set to ${FAKE_HOME}" 1>&2
        # Register cleanup trap on exit
        trap 'rm -rf ${FAKE_HOME}' EXIT

        # Copy local caches into fake home to speed things up.
        declare -a CACHE_DIRS=('.sbt' '.ivy2/cache' '.coursier/cache/v1' '.cache/coursier/v1')

        for d in ${CACHE_DIRS[*]}
        do
            TARGET_PATH="${FAKE_HOME}/${d}"
            ORIGIN_PATH="${HOME}/${d}"

            if [ -d "$ORIGIN_PATH" ]
            then
                mkdir -vp "$TARGET_PATH"
                cp -Rv "${ORIGIN_PATH}/"* "$TARGET_PATH"
            else
                continue
            fi
        done
        readonly FAKE_HOME
    fi

    export HOME="${FAKE_HOME}"
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} -Duser.home=${FAKE_HOME}"
}

# Checks if a git project pointed to by the current directory is clean
# (no updates to tracked files, no new untracked files).
is_git_project_clean() {
    git update-index --refresh && git diff-index --quiet @ --
}

# Run the release
#
# The release has four hooks/steps, each of which can be overridden by
# setting an environment variable.
#
# Hooks/Steps
#
# * clean (environment variable name: SBT_CLEAN_ACTION)
#   * Clean the project before building. Defaults to '+clean'.
# * publishLocal (environment variable name: SBT_PUBLISH_LOCAL_ACTION)
#   * Publish the project locally. Defaults to '+publishLocal'.
# * build (environment variable name: SBT_TASKS)
#   * Run the build and any tests. Defaults to ';+compile;+test;+doc'.
# * publish (environment variable name: SBT_PUBLISH_ACTION)
#   * Publish the project. Defaults to '+publishSigned'
sbt_release() {
    local -r DEFAULT_SBT_CLEAN_ACTION='+clean'
    local -r DEFAULT_SBT_PUBLISH_LOCAL_ACTION='+publishLocal'
    local -r DEFAULT_SBT_PUBLISH_ACTION='+publishSigned'
    local -r DEFAULT_SBT_TASKS=';+compile;+test;+doc'

    if is_git_project_clean || [ "$DRY_RUN" -eq 1 ]
    then
        # Publish locally first for the scripted tests.
        sbt "${SBT_CLEAN_ACTION:-$DEFAULT_SBT_CLEAN_ACTION}"
        sbt "${SBT_PUBLISH_LOCAL_ACTION:-$DEFAULT_SBT_PUBLISH_LOCAL_ACTION}"
        sbt "${SBT_TASKS:-$DEFAULT_SBT_TASKS}"

        # Exit here on DRY_RUN
        if [ "$DRY_RUN" -eq 1 ]
        then
            return 0
        fi

        read -r -p 'Continue with publish? Type (YES): ' PUBLISH
        if [ "${PUBLISH:?}" = 'YES' ]
        then
            sbt "${SBT_PUBLISH_ACTION:-$DEFAULT_SBT_PUBLISH_ACTION}"
        else
            echo "${PUBLISH} is not YES. Aborting." 1>&2
        fi
    else
        echo 'Uncommited local changes. Aborting' 1>&2
        return 1
    fi
}
