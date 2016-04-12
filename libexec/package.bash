#!/usr/bin/env bash
set -o errexit

shopt -s globstar

# Dependency checking
declare -A DEPENDENCIES=(
	["git --version"]="git is not installed, get it from\n  http://git-scm.com/"
)
source "${PREFIX}/lib/deps.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} package [ -h ] [ -q ] <git_tag> <location> <targets>*

Build application and package it for each supported targeted platform.

<git_tag>   specifies which tag to package
<location>  specifies where the final packages should be stored
<targets>   are a list of OS_ARCH identifiers, i.e: darwin_amd64, linux_x86

Options:
    -h  Show this help screen
    -q  Silent mode, useful when calling from scripts

EOF
}

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

git_tag="${1}"
location="${2}"
targets=(${@:3})

required_args=( "git_tag" "location" "targets" )
for arg in "${required_args[@]}"; do
	if [[ -z "${!arg}" ]]; then
		echo -e "Error: please provide missing argument <${arg}>\n"
		usage
		exit 1
	fi
done

# Change location to be an absolute path
mkdir -p "${location}"
location="$(cd "${location}" && pwd)"

# build_tmp_dir is where all the intermediate files will be stored
build_tmp_dir="$(mktemp -d -t ${APP_NAME})"

# creates a copy of the repository at the provided git tag
if ! $quiet; then
	echo "Preparing ${git_tag} for build"
fi
mkdir -p "${build_tmp_dir}/source"
git archive --format=tar "${git_tag}" | tar -x -C "${build_tmp_dir}/source"
( cd "${build_tmp_dir}/source"; go generate ./... )

# Build the app for the targeted os and arch
for target in "${targets[@]}"; do
	if ! $quiet; then
		echo "Building and packaging for ${target}"
	fi

	fn="${APP_NAME}.${git_tag}-${target}"
	pkg_path="${build_tmp_dir}/${fn}"

	(
		export GOOS=$(echo $target | cut -d "_" -f 1)
		export GOARCH=$(echo $target | cut -d "_" -f 2)

		# Compile binary into bin/
		mkdir -p "${pkg_path}/bin"

		if [[ "$(type -t do_build)"  == "function" ]]; then
			do_build "${pkg_path}/bin/${APP_NAME}"
		else
			echo "do_build is not defined"
			exit 1
		fi

		# Copy anything under a _shared folder into the share folder
		mkdir -p "${pkg_path}/share"
		cp -R **"/_share/"* "${pkg_path}/share/"

		if [[ "$(type -t do_post_package)"  == "function" ]]; then
			(cd "${pkg_path}" && do_post_package)
		fi
	)

	(
		cd "$(dirname "${pkg_path}")" &&
		tar -j -c -f "${location}/${fn}.tar.bz2" "$(basename "${pkg_path}")"
	)
done
