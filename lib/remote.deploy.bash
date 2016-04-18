function deploy_setup {
	mkdir -p "${DEPLOY_PATH}/shared/log" "${DEPLOY_PATH}/releases"
}

function deploy_list_releases {
	if [[ -z $(ls -1r "${DEPLOY_PATH}/releases/") ]]; then
		echo "No releases available"
		return
	fi

	echo -e "Releases (${DEPLOY_PATH}):\n"

	for deploy in `deploy_list_deploy_versions`; do
		if [[ "${DEPLOY_PATH}/releases/${deploy}" == "$(readlink "${DEPLOY_PATH}/current")" ]]; then
			echo "  * ${deploy} (current)"
		else
			echo "  * ${deploy}"
		fi
	done

	echo ""
}

function deploy_list_deploy_versions {
	for dir in $(ls -1r "${DEPLOY_PATH}/releases/"); do
		echo "$(basename "${dir}")"
	done
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

function deploy_clean_releases {
	output=`deploy_list_deploy_versions`
	for deploy in $(echo "${output}" | tail -n +11); do
		rm -rf "${DEPLOY_PATH}/releases/${deploy}"
	done
}

function deploy_restart {
	/usr/bin/sudo /usr/sbin/service "${APP_NAME}" restart
}
