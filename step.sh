#!/bin/bash

echo "Running"

set -ex
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#echo "THIS_SCRIPT_DIR = ${THIS_SCRIPT_DIR}"

#ls "${THIS_SCRIPT_DIR}"

#tmp_gopath_dir="$(mktemp -d)"

#go_package_name="github.com/bitrise-steplib/steps-hockeyapp-android-deploy"
#full_package_path="${tmp_gopath_dir}/src/${go_package_name}"
#mkdir -p "${full_package_path}"

#rsync -avh --quiet "${THIS_SCRIPT_DIR}/" "${full_package_path}/"

#export GOPATH="${tmp_gopath_dir}"
#go run "${full_package_path}/main.go"

ruby "${THIS_SCRIPT_DIR}/main.rb"
pwd

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:
#  envman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'
# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
