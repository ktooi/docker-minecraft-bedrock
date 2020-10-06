#!/bin/bash

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

./${BEDROCK_SERVER_BIN:-"bedrock_server"}
