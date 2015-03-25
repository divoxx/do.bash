# Check if any dependency is missing with explanation on how to stall it.
# If a dependency is missing exit with status code 1.
# It expects a DEPENDENCIES variable to be defined.
function check_deps {
	local status=0

	for cmd in "${!DEPENDENCIES[@]}"; do
		if [[ $status -ne 0 ]]; then
			echo ""
		fi

		if ! ${cmd} > /dev/null 2>&1; then
			echo -e "${DEPENDENCIES[$cmd]}"
			status=1
		fi
	done

	return $status
}

check_deps
