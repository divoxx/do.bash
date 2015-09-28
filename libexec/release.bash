#!/usr/bin/env bash
set -o errexit

# Dependency checking
declare -A DEPENDENCIES=(
	["ghr -help 2>&1 | grep -q Usage"]="GHR is not installed, get it from\n  https://github.com/tcnksm/ghr"
)
if [[ "${RELEASE_S3_S3CFG}" ]]; then
	DEPENDENCIES["s3cmd --version"]="s3cmd is not installed, get it from\n  https://github.com/s3tools/s3cmd"
fi
source "${PREFIX}/lib/deps.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} release [ -h ] [ -q ] [ -t ] <git_tag>

Builds and release a new binary distribution of the project.

<git_tag> the git tag of the app to be released

Options:
    -h  Show this help screen
    -q  Silent mode, useful when calling from scripts
    -t  Create the git tag

EOF
}

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
	git pull --tags
	git tag -am "Creating release tag ${git_tag}" "${git_tag}"
	git push --tags
fi

tmp_dir="$(mktemp -d -t "${APP_NAME}.${git_tag}")"
eval "${PREFIX}/libexec/package.bash" "$($quiet && echo "-q")" "${git_tag}" "${tmp_dir}" darwin_amd64 linux_amd64 linux_386

if ! $quiet; then
	echo "Releasing on github"
fi
ghr -u doximity -r auth-api --replace "${git_tag}" "${tmp_dir}"

if [[ "${RELEASE_S3_S3CFG}" && "${RELEASE_S3_BUCKET}" ]]; then
	pkgs=( "${tmp_dir}"/* )

	if ! $quiet; then
		echo "Uploading packages to s3"
	fi
	s3cmd -c "${RELEASE_S3_S3CFG}" put "${pkgs[@]}" s3://${RELEASE_S3_BUCKET}

	for pkg in "${pkgs[@]}"; do
		# Generate signed URLs valid for a year
		echo "-> ${pkg}"
		s3cmd -c "${RELEASE_S3_S3CFG}" signurl "s3://${RELEASE_S3_BUCKET}/$(basename "${pkg}")" +31536000
	done
fi
