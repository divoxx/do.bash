#!/usr/bin/env bash
set -o errexit

function usage {
	cat <<EOF
Usage: ${HELP_NAME} run <app_args]

Build application for local development and run it.

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

eval "${PREFIX}/libexec/build.bash" "$($quiet && echo "-q")"

if ! $quiet; then
	echo "Running application"
fi
eval "./${APP_NAME}" "${@}"
