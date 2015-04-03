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
Usage: ${HELP_NAME} prod-release [ -h ] [ -q ] <git_tag>

Deploy the current code to production

<git_tag> the git tag of the app to be released

Options:
    -h  Show this help screen
    -q  Silent mode, useful when calling from scripts
    -t  Create the git tag

EOF
}

if [[ -z "${DEPLOY_PATH}" ]]; then
	echo "DEPLOY_PATH needs to be set"
	exit 101
fi

if [[ -z "${DEPLOY_HOSTS}" ]]; then
	echo "DEPLOY_HOSTS needs to be set"
	exit 101
fi

if [[ -z "${DEPLOY_PLATFORM}" ]]; then
	echo "DEPLOY_PLATFORM needs to be set"
	exit 101
fi

quiet=false
create_tag=false

while getopts ":hqt" opt; do
	case $opt in
		h)
			usage
			exit 0
			;;
		q)
			quiet=true
			;;
		t)
			create_tag=true
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

git_tag="${1}"
if [[ -z "${git_tag}" ]]; then
	echo "Error: please provide a git_tag"
	echo ""
	usage
	exit 1
fi

if $create_tag; then
	if ! $quiet; then
		echo "Creating git tag ${git_tag}"
	fi
	git tag -am "Creating tag for prod-release ${git_tag}" "${git_tag}"
fi

tmp_dir="$(mktemp -d -t "${APP_NAME}")"
eval "${PREFIX}/libexec/package.bash" "$($quiet && echo "-q")" "${git_tag}" "${tmp_dir}" "${DEPLOY_PLATFORM}"

if ! $quiet; then
	echo "Deploy to production"
fi
cat > "${tmp_dir}/deploy_script.bash" <<EOF
deploy_release ${git_tag}
deploy_restart
EOF
remote_exec "${PREFIX}/lib/remote.deploy.bash" "${tmp_dir}/deploy_script.bash" < "${tmp_dir}/${APP_NAME}.${git_tag}-${DEPLOY_PLATFORM}.tar.bz2"
