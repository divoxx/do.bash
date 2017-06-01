#!/usr/bin/env bash
set -o errexit

# Include dependencies
source "${PREFIX}/lib/remote.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} list-deploys [ -h ] <env>

Deploy the current available releases in production's history

<env> is the target environment: prod, amstel

Options:
    -h  Show this help screen

EOF
}

quiet=false

while getopts ":hq" opt; do
	case $opt in
		h)
			usage
			exit 0
			;;
		\?)
			echo "Error: invalid option -${opt}"
			usage
			exit 1
			;;
		:)
			echo "Error: option -${opt} requires an argument"
			usage
			exit 2
			;;
	esac
done
shift $((OPTIND-1))

env="${1}"
if [[ -z "${env}" ]]; then
	echo "Error: please provide an env"
	echo ""
	usage
	exit 1
fi

deploy_path_var="${env^^}_DEPLOY_PATH"
deploy_hosts_var="${env^^}_DEPLOY_HOSTS"
deploy_platform_var="${env^^}_DEPLOY_PLATFORM"

export DEPLOY_PATH=${!deploy_path_var}
export DEPLOY_HOSTS=${!deploy_hosts_var}
export DEPLOY_PLATFORM=${!deploy_platform_var}

tmp=$(mktemp --tmpdir -d ${APP_NAME}.prod-list-releases.XXXXX)
cat > "${tmp}" <<EOF
DEPLOY_PATH="${DEPLOY_PATH}"
deploy_list_releases
EOF
remote_parallel_exec "${PREFIX}/lib/remote.deploy.bash" "${tmp}"
