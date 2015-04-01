function deploy_setup {
	mkdir -p "${DEPLOY_PATH}/shared/log" "${DEPLOY_PATH}/releases"
}

function deploy_list_releases {
	if [[ -z $(ls -1r "${DEPLOY_PATH}/releases/") ]]; then
		echo "No releases available"
		return
	fi

	echo -e "Releases (${DEPLOY_PATH}):\n"

	for dir in $(ls -1r "${DEPLOY_PATH}/releases/"); do
		if [[ "${DEPLOY_PATH}/releases/${dir}" == "$(readlink "${DEPLOY_PATH}/current")" ]]; then
			echo "  * $(basename "${dir}") (current)"
		else
			echo "  * $(basename "${dir}")"
		fi
	done

	echo ""
}

function deploy_release {
	deploy_setup
	local name="$(date -u "+%Y-%m-%dT%H:%M:%S")-${1}"

	mkdir -p "${DEPLOY_PATH}/releases/${name}"
	tar -jxvm --strip-components 1 -C "${DEPLOY_PATH}/releases/${name}"
	ln -sTfv "${DEPLOY_PATH}/releases/${name}" "${DEPLOY_PATH}/current"

	for rel in $(ls "${DEPLOY_PATH}" | head -n -10); do
		rm -ri "${DEPLOY_PATH}/releases${rel}"
	done
}

function deploy_restart {
	/usr/bin/sudo /usr/bin/sv restart ${APP_NAME}
}
