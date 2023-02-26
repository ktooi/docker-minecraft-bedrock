#!/bin/bash

: ${BASE_DIR:="$(cd $(dirname $0); pwd)"}

: ${BACKUP_DIR:="${BASE_DIR}/backup"}
: ${CONTAINERS_LST:="${BASE_DIR}/containers.lst"}

declare -a CONTAINERS

function run_container() {
	local __name="$1"
	local __port="$2"
	local __volume="$3"
	local __image="$4"
	local __env_file="${BASE_DIR}/env-files/${__name}.env"
	declare -a __opts=(-d -p "${__port}:${__port}/udp" -e "SERVER_PORT=${__port}" -v "${__volume}:/volume" --name "${__name}")
	[ -e "${__env_file}" ] && __opts+=(--env-file "${__env_file}")
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

function main() {
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
