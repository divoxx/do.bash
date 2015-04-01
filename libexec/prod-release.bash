#!/usr/bin/env bash
set -o errexit

# Dependency checking
declare -A DEPENDENCIES=(
	["ssh -V"]="ssh is not installed"
)

# Include dependencies
source "${PREFIX}/lib/deps.bash"
source "${PREFIX}/lib/remote.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} prod-release [ -h ] [ -q ] <version>

Deploy the current code to production

<version> the version of the app to be released

Options:
    -h  Show this help screen
    -q  Silent mode, useful when calling from scripts

EOF
}

if [[ -z "${DEPLOY_PATH}" ]]; then
	echo "DEPLOY_PATH needs to be set"
	exit 101
fi

if [[ -z "${DEPLOY_HOSTS[*]}" ]]; then
	echo "DEPLOY_HOSTS needs to be set"
	exit 101
fi

if [[ -z "${DEPLOY_PLATFORM}" ]]; then
	echo "DEPLOY_PLATFORM needs to be set"
	exit 101
fi

quiet=false

while getopts ":hq" opt; do
	case $opt in
		h)
			usage
			exit 0
			;;
		q)
			quiet=true
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

version="${1}"
if [[ -z "${version}" ]]; then
	echo "Error: please provide a version"
	echo ""
	usage
	exit 1
fi

tmp_dir="$(mktemp -d -t "${APP_NAME}")"
eval "${PREFIX}/libexec/package.bash" "$($quiet && echo "-q")" "v${version}" "${tmp_dir}" "${DEPLOY_PLATFORM}"

if ! $quiet; then
	echo "Deploy to production"
fi
cat > "${tmp_dir}/deploy_script.bash" <<EOF
deploy_release ${version}
EOF
remote_exec "${PREFIX}/lib/remote.deploy.bash" "${tmp_dir}/deploy_script.bash" < "${tmp_dir}/${APP_NAME}.v${version}-${DEPLOY_PLATFORM}.tar.bz2"
