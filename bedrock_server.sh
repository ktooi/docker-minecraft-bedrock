#!/bin/bash

set -ue

BASE_DIR=$(cd $(basename "$0"); pwd)

__BEDROCK_SERVER_URL=""
__BEDROCK_SERVER_URL_VER_PAT='https:\/\/minecraft\.azureedge\.net\/bin-linux\/bedrock-server-([0-9]+\.[0-9]+\.[0-9]+\.[0-9])\.zip'
function __get_bedrock_server_url() {
	__BEDROCK_SERVER_URL=$(wget https://www.minecraft.net/ja-jp/download/server/bedrock/ -O - 2>/dev/null | grep -E -o "${__BEDROCK_SERVER_URL_VER_PAT}")
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

function download_bedrock_server_latest_file() {
	wget $(get_bedrock_server_url) -O ${BASE_DIR}/$(get_bedrock_server_latest_filename)
}

function build_docker_image() {
	cd ${BASE_DIR}
	local __bsv="$1"
	docker build --build-arg BEDROCK_SERVER_VER="$__bsv" -t "bedrock:latest" .
	docker build --build-arg BEDROCK_SERVER_VER="$__bsv" -t "bedrock:$__bsv" .
}

function main() {
	if has_bedrock_server_latest_file; then
		: # Nothing to do.
	else
		download_bedrock_server_latest_file
		build_docker_image $(get_bedrock_server_latest_ver)
	fi
}

main
