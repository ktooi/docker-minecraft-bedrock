#!/bin/bash

: ${BASE_DIR:="$(cd $(dirname "$0"); pwd)"}

: ${I_AGREE_TO_MEULA_AND_PP:=""}
: ${REPOSITORY:="bedrock"}
# BEDROCK_SERVER_DIR must be relative path.
# BEDROCK_SERVER_DIR は相対パスでなければなりません。
: ${BEDROCK_SERVER_DIR:="./downloads"}

: ${USER_AGENT:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"}

__BEDROCK_SERVER_URL=""
__BEDROCK_SERVER_URL_VER_PAT='https:\/\/minecraft\.azureedge\.net\/bin-linux\/bedrock-server-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.zip'
function __get_bedrock_server_url() {
	__BEDROCK_SERVER_URL=$(curl -A "${USER_AGENT}" -Ls https://www.minecraft.net/en-us/download/server/bedrock/ 2>/dev/null | grep -E -o "${__BEDROCK_SERVER_URL_VER_PAT}")
}

function get_bedrock_server_url() {
	[ -z "${__BEDROCK_SERVER_URL}" ] && __get_bedrock_server_url
	echo ${__BEDROCK_SERVER_URL}
}

function get_bedrock_server_latest_filename() {
	basename $(get_bedrock_server_url)
}

function get_bedrock_server_latest_ver() {
	get_bedrock_server_url | sed -E "s/${__BEDROCK_SERVER_URL_VER_PAT}/\1/"
}

function has_bedrock_server_latest_file() {
	[ -e ${BASE_DIR}/${BEDROCK_SERVER_DIR}/$(get_bedrock_server_latest_filename) ]
}

function ask_agree_meula() {
	while [ "${I_AGREE_TO_MEULA_AND_PP}" != "yes" -a "${I_AGREE_TO_MEULA_AND_PP}" != "no" ]
	do
		read -p "I agree to Minecraft End User License Agreement and Privacy Policy. (yes/no): " I_AGREE_TO_MEULA_AND_PP
	done
}

function download_bedrock_server_latest_file() {
	ask_agree_meula
	if [ "${I_AGREE_TO_MEULA_AND_PP}" == "yes" ]; then
		curl -A "${USER_AGENT}" -s $(get_bedrock_server_url) -o "${BASE_DIR}/${BEDROCK_SERVER_DIR}/$(get_bedrock_server_latest_filename)"
	else
		echo "You must agree to Minecraft End User License Agreement and Privacy Policy."
		return 1
	fi
}

function build_docker_image() {
	local __bsv="$1"
	docker build --build-arg BEDROCK_SERVER_DIR="${BEDROCK_SERVER_DIR}" --build-arg BEDROCK_SERVER_VER="$__bsv" -t "${REPOSITORY}:$__bsv" ${BASE_DIR}
}

function get_latest_ver_of_image() {
	docker images "${REPOSITORY}" --format '{{.Tag}}' | grep -v '^latest$' | sort -V | tail -n1 | sed -e "s/^[^ ]* //"
}

function set_latest_tag_to_latest_ver_image() {
	docker tag "${REPOSITORY}:$(get_latest_ver_of_image)" "${REPOSITORY}:latest"
}

function set_minor_tag_to_latest_ver_image() {
	__latest_ver=$(get_latest_ver_of_image)
	docker tag "${REPOSITORY}:${__latest_ver}" "${REPOSITORY}:$(sed -e "s/^\([0-9]\+\.[0-9]\+\)\..*$/\1/" <<< "${__latest_ver}" )"
}

function has_bedrock_server_image() {
	local __ver="$1"
	[ -n "$(docker images "${REPOSITORY}:${__ver}" --format {{.Tag}})" ]
}

function main() {
	if [ "${1:-""}" == "--i-agree-to-meula-and-pp" ]; then
		I_AGREE_TO_MEULA_AND_PP="yes"
	fi
	if [ "${1:-""}" == "--force-build" ]; then
		FORCE_BUILD="yes"
	fi
	# Fetch the latest version URL of the BRS and set to cache.
	# Because the cache can not store the value if called in subprocess (like "$()").
	get_bedrock_server_url >/dev/null

	if has_bedrock_server_latest_file; then
		: # Nothing to do.
	else
		download_bedrock_server_latest_file
	fi
	__brs_latest_var=$(get_bedrock_server_latest_ver)
	if ! has_bedrock_server_image "${__brs_latest_var}" || [ "${FORCE_BUILD:-""}" == "yes" ]; then
		# If the latest version of the BRS image does not exist, build it.
		build_docker_image "${__brs_latest_var}"
	fi
	set_latest_tag_to_latest_ver_image
	set_minor_tag_to_latest_ver_image
}

if [ -z "${BS_IMPORT:-""}" ]; then
	set -ue

	main "$@"
fi
