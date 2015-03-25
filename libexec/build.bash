#!/usr/bin/env bash
set -o errexit

# Dependency checking
declare -A DEPENDENCIES=(
	["godep help"]="godep is not installed, run\n  go get -u github.com/tools/godep"
	["go-bindata -version"]="go-bindata is not installed, run\n  go get -u github.com/jteeuwen/go-bindata/..."
)
source "${PREFIX}/lib/deps.bash"

function usage {
	cat <<EOF
Usage: ${HELP_NAME} local [ -h ] [ -q ]

Build application for local development into the pkg folder

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

if ! $quiet; then
	echo "Running go generate for package"
fi
godep go generate ./...

if ! $quiet; then
	echo "Building application"
fi
godep go build -o "${APP_NAME}" -ldflags "-X '${PACKAGE}/http.rootDir' '${PACKAGE_PATH}/http'"
