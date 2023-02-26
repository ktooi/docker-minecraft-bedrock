#!/bin/bash

: ${BASE_DIR:="$(cd $(dirname $0); pwd)"}

: ${BACKUP_DIR:="${BASE_DIR}/backup"}
: ${CONTAINERS_LST:="${BASE_DIR}/containers.lst"}
: ${ADDONS_DIR:="${BASE_DIR}/addons"}
: ${EXTRACT_ADDONS_DIR:="${ADDONS_DIR}/extracted"}

declare -a CONTAINERS

function run_container() {
	local __name="$1"
	local __port="$2"
	local __volume="$3"
	local __image="$4"
	local __env_file="${BASE_DIR}/env-files/${__name}.env"
	local __addon_lst_file="${ADDONS_DIR}/${__name}.addons"
	declare -a __opts=(-d -p "${__port}:${__port}/udp" -e "SERVER_PORT=${__port}" -v "${__volume}:/volume" -v "${EXTRACT_ADDONS_DIR}:/addons:ro" --name "${__name}")
	[ -e "${__env_file}" ] && __opts+=(--env-file "${__env_file}")
	[ -e "${__addon_lst_file}" ] && __opts+=(-v "${__addon_lst_file}:/addons.lst:ro")
	docker run "${__opts[@]}" "${__image}"
}

function start_container() {
	local __name="$1"
	docker start "${__name}"
}

function stop_container() {
	local __name="$1"
	docker stop "${__name}"
}

function read_containers_lst() {
	local IFS=$'\n'
	CONTAINERS=($(sed -e 's/[ \t]*#.*$//' -e '/^[ \t]*$/d' ${CONTAINERS_LST}))
}

function get_container_id() {
	local __name="$1"
	docker ps -a -f "name=/${__name}\$" --format '{{.ID}}'
}

function get_container_image() {
	local __id="$1"
	docker ps -a -f "id=${__id}" --format '{{.Image}}'
}

function remove_container() {
	local __id="$1"
	local __volume="$2"
	if is_up "${__id}"; then
		stop_container "${__id}"
	fi
	backup_volume "${__volume}"
	docker rm "${__id}"
}

function backup_volume() {
	local __volume="$1"
	# FYI : https://qiita.com/nishina555/items/bebcf76ca7890f257530
	docker run --rm -v "${__volume}:/volume" -v "${BACKUP_DIR}:/backup" busybox tar cvzf "/backup/${__volume}.$(date +%Y%m%d%H%M%S).tar.gz" /volume
}

function is_up() {
	local __id="$1"
	[[ "$(docker ps -a -f "id=${__id}" --format '{{.Status}}')" =~ ^Up ]]
}

function get_addon_lst() {
	local IFS=$'\n'
	ADDON_LST=($(find "${ADDONS_DIR}" -maxdepth 1 -name "*.mcpack" -o -name "*.mcworld"))
}

function extract_addon() {
	local __addon="$1"
	__addon_ext="$(basename "$1" | sed -e "s/^.*\.\([^.]\+\)$/\1/")"

	if [ "${__addon_ext}" == "mcpack" ]; then
		extract_mcpack "${__addon}"
	elif [ "${__addon_ext}" == "mcworld" ]; then
		extract_mcworld "${__addon}"
	fi
}

function extract_mcpack() {
	local __addon="$1"
	__addon_dirname="$(basename "$1" | sed -e "s/\.[^.]\+$//")"

	# manifest.json のみを展開し、 Addon の情報を取得。
	__tmp_dir="$(mktemp -d "${ADDONS_DIR}/tempXXXX")"
	: $(cd "${__tmp_dir}"; unzip "${__addon}" manifest.json)
	__manifest_file="${__tmp_dir}/manifest.json"
	__addon_uuid=$(jq -r '.header.uuid' "${__manifest_file}")
	__addon_ver=$(jq -c '.header.version' "${__manifest_file}")
	__addon_ver_us=$(tr , '_' <<< ${__addon_ver} | tr -d '[]')
	__addon_type=$(jq -r '.modules[0].type' "${__manifest_file}")
	rm -rf "${__tmp_dir}"

	__addon_dir="${EXTRACT_ADDONS_DIR}/${__addon_type}/by-uuid_ver/${__addon_uuid}_${__addon_ver_us}"
	if [ ! -d "${__addon_dir}" ]; then
		mkdir -p "${__addon_dir}"
		: $(cd "${__addon_dir}"; unzip "${__addon}")
		echo "{\"pack_id\": \"${__addon_uuid}\", \"version\": ${__addon_ver}}" > "${__addon_dir}/.docker-bedrock.json"
	fi
	[ ! -d "${EXTRACT_ADDONS_DIR}/${__addon_type}/by-name/" ] && mkdir "${EXTRACT_ADDONS_DIR}/${__addon_type}/by-name/"
	__addon_dir_by_name="${EXTRACT_ADDONS_DIR}/${__addon_type}/by-name/${__addon_dirname}"
	[ ! -L "${__addon_dir_by_name}" ] && ln -s "../by-uuid_ver/${__addon_uuid}_${__addon_ver_us}" "${__addon_dir_by_name}"

	return 0
}

function extract_mcworld() {
	local __addon="$1"
	__addon_dirname="$(basename "$1" | sed -e "s/\.[^.]\+$//")"

	__addon_type="worlds"
	__addon_dir="${EXTRACT_ADDONS_DIR}/${__addon_type}/${__addon_dirname}"
	if [ ! -d "${__addon_dir}" ]; then
		mkdir -p "${__addon_dir}"
		: $(cd "${__addon_dir}"; unzip "${__addon}")
	fi
}

function main() {
	[ ! -d "${EXTRACT_ADDONS_DIR}" ] && mkdir -p "${EXTRACT_ADDONS_DIR}"
	get_addon_lst
	for __addon in "${ADDON_LST[@]}"
	do
		extract_addon "${__addon}"
	done
	read_containers_lst
	for __container in "${CONTAINERS[@]}"
	do
		declare -a __t
		__t=(${__container//\\t/ })
		name="${__t[0]}"
		port="${__t[1]}"
		volume="${__t[2]}"
		image="${__t[3]}"
		echo "Start processing for ${name}."
		container_id=$(get_container_id "${name}")
		if [ -z "${container_id}" ]; then
			echo "Container named ${name} does not exist. It will be created and running."
			run_container "${name}" "${port}" "${volume}" "${image}"
		else
			c_image=$(get_container_image "${container_id}")
			if [ "${image}" != "${c_image}" ]; then
				echo "Container named ${name} was exist. But it has wrong image (this may be due to that image was updated). So it will be remove, create and running."
				remove_container "${container_id}" "${volume}"
				run_container "${name}" "${port}" "${volume}" "${image}"
			else
				if is_up "${container_id}"; then
					: # Nothing to do.
				else
					start_container "${container_id}"
				fi
			fi
		fi
		echo "End processing for ${name}."
	done
}

if [ -z "${MC_IMPORT:-""}" ]; then
	set -ue
	main
fi
