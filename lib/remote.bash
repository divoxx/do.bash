# Dependency checking
declare -A DEPENDENCIES=(
	["ssh -V"]="ssh is not installed"
	["parallel --version"]="parallel is not installed"
)
source "${PREFIX}/lib/deps.bash"

function remote_exec {
	local tmp="$(mktemp -d -t ${APP_NAME}.remote)"

	read -a hosts <<< "${DEPLOY_HOSTS}"

	(
		cd "${tmp}"
		mkdir "payload"

		if [[ ! -t 0 ]]; then
			cat > "payload/upload"
		fi

		cat > "payload/runner.bash" <<EOF
set -o errexit
if [[ -f "payload/upload" ]]; then
	bash payload/script.bash < payload/upload
else
	bash payload/script.bash
fi
EOF

		cat > "payload/script.bash" <<EOF
set -o errexit
APP_NAME="${APP_NAME}"
DEPLOY_PATH="${DEPLOY_PATH}"
$(for i in "${@}"; do cat "${i}"; done)
EOF

		parallel --tagstring '[{1}]' 'tar -c payload | ssh {1} -- {2}' ::: "${hosts[@]}" ::: "cd \"\$(mktemp -d)\" && tar -xm && bash payload/runner.bash"
	)
}
