#!/bin/bash

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
__EOT__

for __dir in worlds
do
  [ ! -d /volume/${__dir} ] && mkdir /volume/${__dir}
  [ -d ./${__dir} ] && rmdir ./${__dir}
  ln -s /volume/${__dir} ./${__dir}
done

for __file in whitelist.json permissions.json
do
  [ ! -f /volume/${__file} ] && touch /volume/${__file}
  [ -f ./${__file} ] && rm ./${__file}
  ln -s /volume/${__file} ./${__file}
done

./bedrock_server
