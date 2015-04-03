#!/usr/bin/env bash
set -o errexit

# Dependency checking
declare -A DEPENDENCIES=(
	["hub --version"]="Github's hub is not installed, get it from\n  https://github.com/github/hub"
)
if [[ "${RELEASE_S3_S3CFG}" ]]; then
	DEPENDENCIES["s3cmd --version"]="s3cmd is not installed, get it from\n  https://github.com/s3tools/s3cmd"
fi
source "${PREFIX}/lib/deps.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} release [ -h ] [ -q ] [ -p ] <version>

Builds and release a new binary distribution of the project.

<version>  the version to be released, requires a git tag v\${version}

Options:
    -h  Show this help screen
    -q  Silent mode, useful when calling from scripts
    -p  Preview release

EOF
}

quiet=false
preview=false

while getopts ":hqp" opt; do
	case $opt in
		h)
			usage
			exit 0
			;;
		q)
			quiet=true
			;;
		p)
			preview=true
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

git_tag="v${version}"

tmp_dir="$(mktemp -d -t "${APP_NAME}.${version}")"
eval "${PREFIX}/libexec/package.bash" "$($quiet && echo "-q")" "${git_tag}" "${tmp_dir}" darwin_amd64 linux_amd64 linux_386
pkgs=( "${tmp_dir}"/* )

if ! $quiet; then
	echo "Releasing on github"
fi
hub release create "$($preview && echo "-p")" -f <(echo -e "AuthAPI ${version}\n\nSee [README.md](README.md)") ${pkgs[@]/#/-a } "${git_tag}"

if [[ "${RELEASE_S3_S3CFG}" && "${RELEASE_S3_BUCKET}" ]]; then
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
