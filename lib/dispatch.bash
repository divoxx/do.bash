#!/usr/bin/env bash
set -o errexit

# The following are variables that needs to be defined by your project:
#
# APP_NAME
#   the name of the application, which also impacts the binary name
#   i.e. export APP_NAME="my-app"
#
# PACKAGE
#   is the canonical import path of your package
#   i.e. github.com/user/pkg_repo
#
# DEPLOY_HOSTS
#  the array of hosts in which the application will be deployed
#  i.e. export DEPLOY_HOSTS=( "192.168.0.10" "192.168.0.11" )
#
# DEPLOY_PATH
#   the absolute path to where the application will be deployed
#   i.e. export DEPLOY_PATH="/var/apps/"
#
# DEPLOY_PLATFORM
#   the platform of the machines in which the application will be deployed
#   i.e. export DEPLOY_PLATFORM="linux_amd64"

# This is the string that should be used to identify the binary on help/usage screens.
export HELP_NAME="${0}"

# PREFIX is exported so that all imported files and libs can refer to the absolute
# path in which this tool instalation resides.
export PREFIX="$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )"

# The path to this package inside GOPATH
export PACKAGE_PATH="${GOPATH}/src/${PACKAGE}"

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
	echo "Error: bash >= 4 is required"
	echo "  On OSX? brew install bash, and prepend /usr/local/bin/bash to /etc/shells"
	exit 100
fi

# Command dispatching
function usage {
	cat <<EOF
Usage: ${HELP_NAME} [ <command> | help <command> ]

Implements a banch of build tools for $(basename "${0}").

Commands:
    build               Builds the application for local development
    package             Builds the application for distribution
    prod-list-releases  List the available releases on the deploy hosts
    prod-release        Release a version to production
    release             Tag a new version, builds it and release it on Github.

EOF
}

function dispatch {
	# Dispatch to subcommand
	if [[ -z "${1}" ]]; then
		usage
	else
		if [[ "${1}" == "help" ]]; then
			args=( "-h" )
			shift
		else
			args="${@:2}"
		fi

		cmd="${PREFIX}/libexec/$(basename "${1}").bash"

		if [[ -e "${cmd}" ]]; then
			(cd "${PACKAGE_PATH}"; eval "${cmd}" "${args[@]}")
		else
			echo "Error: unknown command ${1}"
			echo ""
			usage
			exit 1
		fi
	fi
}
