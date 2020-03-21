#!/bin/bash

set -ue

BASE_DIR=$(cd $(basename "$0"); pwd)
: ${I_AGREE_TO_MEULA_AND_PP:=""}

__BEDROCK_SERVER_URL=""
__BEDROCK_SERVER_URL_VER_PAT='https:\/\/minecraft\.azureedge\.net\/bin-linux\/bedrock-server-([0-9]+\.[0-9]+\.[0-9]+\.[0-9])\.zip'
function __get_bedrock_server_url() {
	__BEDROCK_SERVER_URL=$(wget https://www.minecraft.net/en-us/download/server/bedrock/ -O - 2>/dev/null | grep -E -o "${__BEDROCK_SERVER_URL_VER_PAT}")
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
	[ -e ${BASE_DIR}/$(get_bedrock_server_latest_filename) ]
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
		wget $(get_bedrock_server_url) -O ${BASE_DIR}/$(get_bedrock_server_latest_filename)
	else
		echo "You must agree to Minecraft End User License Agreement and Privacy Policy."
		return 1
	fi
}

function build_docker_image() {
	cd ${BASE_DIR}
	local __bsv="$1"
	docker build --build-arg BEDROCK_SERVER_VER="$__bsv" -t "bedrock:latest" .
	docker build --build-arg BEDROCK_SERVER_VER="$__bsv" -t "bedrock:$__bsv" .
}

function main() {
	if [ "${1:-""}" == "--i-agree-to-meula-and-pp" ]; then
		I_AGREE_TO_MEULA_AND_PP="yes"
	fi
	if has_bedrock_server_latest_file; then
		: # Nothing to do.
	else
		download_bedrock_server_latest_file
		build_docker_image $(get_bedrock_server_latest_ver)
	fi
}

main
