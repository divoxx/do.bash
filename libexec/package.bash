#!/usr/bin/env bash
set -o errexit

shopt -s globstar

# Dependency checking
declare -A DEPENDENCIES=(
	["git --version"]="git is not installed, get it from\n  http://git-scm.com/"
	["godep help"]="godep is not installed, run\n  go get -u github.com/tools/godep"
	["go-bindata -version"]="go-bindata is not installed, run\n  go get -u github.com/jteeuwen/go-bindata/..."
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

# tmp_dir is where all the intermediate files will be stored
tmp_dir="$(mktemp -d -t ${APP_NAME})"

# creates a copy of the repository at the provided git tag
if ! $quiet; then
	echo "Preparing ${git_tag} for build"
fi
mkdir -p "${tmp_dir}/source"
git archive --format=tar "${git_tag}" | tar -x -C "${tmp_dir}/source"
( cd "${tmp_dir}/source"; godep go generate ./... )

# Build the app for the targeted os and arch
for target in "${targets[@]}"; do
	if ! $quiet; then
		echo "Building and packaging for ${target}"
	fi

	fn="${APP_NAME}.${git_tag}-${target}"
	pkg_path="${tmp_dir}/${fn}"

	(
		export GOOS=$(echo $target | cut -d "_" -f 1)
		export GOARCH=$(echo $target | cut -d "_" -f 2)

		# Compile binary into bin/
		mkdir -p "${pkg_path}/bin"
		godep go build -o "${pkg_path}/bin/${APP_NAME}" -tags release

		# Copy dev configuration environment to etc/${APP_NAME}.conf
		mkdir -p "${pkg_path}/etc/${APP_NAME}"
		cp "_environments/release."* "${pkg_path}/etc/${APP_NAME}/"

		# Copy anything under a _shared folder into the share folder
		mkdir -p "${pkg_path}/share/${APP_NAME}"
		cp -R **"/_share/"* "${pkg_path}/share/${APP_NAME}/"
	)

	(
		cd "$(dirname "${pkg_path}")" &&
		tar -j -c -f "${location}/${fn}.tar.bz2" "$(basename "${pkg_path}")"
	)
done
