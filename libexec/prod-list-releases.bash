#!/usr/bin/env bash
set -o errexit

# Include dependencies
source "${PREFIX}/lib/remote.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} prod-list-releases [ -h ]

Deploy the current available releases in production's history

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

tmp=$(mktemp -t ${APP_NAME}.prod-list-releases)
cat > "${tmp}" <<EOF
DEPLOY_PATH="${DEPLOY_PATH}"
deploy_list_releases
EOF
remote_exec "${PREFIX}/lib/remote.deploy.bash" "${tmp}"
