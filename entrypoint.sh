#!/bin/bash

: ${LEVEL_NAME:="level"}

: ${BASE_DIR:="$(cd $(dirname $0); pwd)"}
: ${BEDROCK_SERVER_BIN:="bedrock_server"}
: ${WORLD_DIR:="/volume/worlds/${LEVEL_NAME}"}
: ${ADDONS_DIR:="/addons"}
: ${ADDON_LST:="/addons.lst"}
: ${RESOURCE_PACKS_DIR:="${BASE_DIR}/resource_packs"}
: ${BEHAVIOR_PACKS_DIR:="${BASE_DIR}/behavior_packs"}
: ${WORLD_RESOURCE_PACKS_FILE:="${WORLD_DIR}/world_resource_packs.json"}
: ${WORLD_BEHAVIOR_PACKS_FILE:="${WORLD_DIR}/world_behavior_packs.json"}

# Specify the permanent directories.
# These directories will load from docker volume and store to docker volume.
# 永続化するディレクトリを指定。
# これらのディレクトリは、 docker volume から読み込まれ、 docker volume に保存されます。
__perm_dirs=("worlds")

# Specify the permanent files.
# These files will load from docker volume and store to docker volume.
# 永続化するファイルを指定。
# これらのファイルは、 docker volume から読み込まれ、 docker volume に保存されます。
__perm_files=("whitelist.json" "permissions.json")

cat <<__EOT__ > ./server.properties
gamemode=${GAMEMODE:-"survival"}
difficulty=${DIFFICULTY:-"easy"}
level-type=${LEVEL_TYPE:-"DEFAULT"}
server-name=${SERVER_NAME:-"Dedicated Server"}
max-players=${MAX_PLAYERS:-"10"}
server-port=${SERVER_PORT:-"19132"}
server-portv6=${SERVER_PORTV6:-"19133"}
level-name=${LEVEL_NAME:-"level"}
level-seed=${LEVEL_SEED:-""}
online-mode=${ONLINE_MODE:-"true"}
white-list=${WHITE_LIST:-"false"}
allow-cheats=${ALLOW_CHEATS:-"false"}
view-distance=${VIEW_DISTANCE:-"10"}
player-idle-timeout=${PLAYER_IDLE_TIMEOUT:-"30"}
max-threads=${MAX_THREADS:-"8"}
tick-distance=${TICK_DISTANCE:-"4"}
default-player-permission-level=${DEFAULT_PLAYER_PERMISSION_LEVEL:-"member"}
texturepack-required=${TEXTUREPACK_REQUIRED:-"false"}
content-log-file-enabled=${CONTENT_LOG_FILE_ENABLED:-"false"}
compression-threshold=${COMPRESSION_THRESHOLD:-"1"}
server-authoritative-movement=${SERVER_AUTHORITATIVE_MOVEMENT:-"true"}
player-movement-score-threshold=${PLAYER_MOVEMENT_SCORE_THRESHOLD:-"20"}
player-movement-distance-threshold=${PLAYER_MOVEMENT_DISTANCE_THRESHOLD:-"0.3"}
player-movement-duration-threshold-in-ms=${PLAYER_MOVEMENT_DURATION_THRESHOLD_IN_MS:-"500"}
correct-player-movement=${CORRECT_PLAYER_MOVEMENT:-"false"}
__EOT__

# Prepare the permanent directories.
# 永続化するディレクトリを準備する。
for __dir in "${__perm_dirs[@]}"
do
  [ ! -d /volume/${__dir} ] && mkdir /volume/${__dir}
  [ -d ./${__dir} -a ! -L ./${__dir} ] && rmdir ./${__dir}
  [ ! -L ./${__dir} ] && ln -s /volume/${__dir} ./${__dir}
done

# Prepare the permanent files.
# 永続化するファイルを準備する。
for __file in "${__perm_files[@]}"
do
  [ ! -f /volume/${__file} ] && touch /volume/${__file}
  [ -f ./${__file} -a ! -L ./${__file} ] && rm ./${__file}
  [ ! -L ./${__file} ] && ln -s /volume/${__file} ./${__file}
done


# ここから Addon 関連の処理

function read_addons() {
	local IFS=$'\n'
	ADDONS=($(sed -e 's/[ \t]*#.*$//' -e '/^[ \t]*$/d' ${ADDON_LST}))
}

function set_addon() {
	local addon="$1"
	local dst_packs_dir="$2"
	local dst_packs_file="$3"
	if [ ! -e "${dst_packs_file}" ]; then
		echo "[" > "${dst_packs_file}"
	else
		echo "," >> "${dst_packs_file}"
	fi
	__packs_line="$(cat "${ADDONS_DIR}/${addon}/.docker-bedrock.json")"
	echo -n "${__packs_line}" >> "${dst_packs_file}"
	__dst_packs_addon_dir="${dst_packs_dir}/$(basename "${addon}"
	[ ! -L "${__dst_packs_addon_dir}" ] && ln -s "${ADDONS_DIR}/${addon}" "${__dst_packs_addon_dir}"

	return 0
}

# world_*_packs.json は冪等性を担保する為に毎回削除し、必要に応じて新規作成する。
[ -e "${WORLD_RESOURCE_PACKS_FILE}" ] && rm "${WORLD_RESOURCE_PACKS_FILE}"
[ -e "${WORLD_BEHAVIOR_PACKS_FILE}" ] && rm "${WORLD_BEHAVIOR_PACKS_FILE}"
if [ -e "${ADDON_LST}" ]; then
	read_addons
	for __addon in "${ADDONS[@]}"
	do
		__type=$(awk -F'/' '{print $1}' <<< "${__addon}")
		if [ "${__type}" == "resources" ]; then
			__packs_dir="${RESOURCE_PACKS_DIR}"
			__packs_file="${WORLD_RESOURCE_PACKS_FILE}"
		elif [ "${__type}" == "data" ]; then
			__packs_dir="${BEHAVIOR_PACKS_DIR}"
			__packs_file="${WORLD_BEHAVIOR_PACKS_FILE}"
		fi
		set_addon "${__addon}" "${__packs_dir}" "${__packs_file}"
	done
	[ -e "${WORLD_RESOURCE_PACKS_FILE}" ] && echo "]" >> "${WORLD_RESOURCE_PACKS_FILE}"
	[ -e "${WORLD_BEHAVIOR_PACKS_FILE}" ] && echo "]" >> "${WORLD_BEHAVIOR_PACKS_FILE}"
fi

chmod 755 ./${BEDROCK_SERVER_BIN}
exec ./${BEDROCK_SERVER_BIN}
