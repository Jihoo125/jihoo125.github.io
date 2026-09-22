
#!/bin/bash
set -euo pipefail

DIR="/opt/minecraft"
JAR="$DIR/server.jar"
ZIP="/tmp/blocked.zip"
TMP="/tmp/blocked-map"

SERVER_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"

MAP_URL="https://mediafilez.forgecdn.net/files/7695/831/Blocked%20in%20Combat%20-%20Remastered_v1.0.2-1.21.11.zip"

echo "== Minecraft 1.21.11 =="

apt-get update -y
apt-get install -y openjdk-21-jre-headless curl unzip screen

mkdir -p "$DIR"

echo "== Downloading server =="
curl -fL --retry 5 --retry-delay 2 "$SERVER_URL" -o "$JAR"

echo "== Downloading map =="
rm -f "$ZIP"

curl -fL --retry 5 --retry-delay 2 "$MAP_URL" -o "$ZIP"

echo "== Checking map =="
unzip -t "$ZIP" >/dev/null

rm -rf "$TMP"
mkdir -p "$TMP"

echo "== Extracting map =="
unzip -q "$ZIP" -d "$TMP"

WORLD="$(find "$TMP" -type f -name level.dat -printf '%h\n' | head -n 1)"

if [ -z "$WORLD" ]; then
    echo "ERROR: level.dat not found."
    exit 1
fi

echo "== Installing world =="
rm -rf "$DIR/world"
cp -a "$WORLD" "$DIR/world"

cat > "$DIR/eula.txt" <<EOF
eula=true
EOF

cat > "$DIR/server.properties" <<EOF
level-name=world
server-port=25565
server-ip=
gamemode=adventure
difficulty=normal
max-players=8
view-distance=8
simulation-distance=6
spawn-protection=0
enable-command-block=true
online-mode=true
pvp=true
motd=Blocked in Combat | Remastered
EOF

rm -f "$ZIP"
rm -rf "$TMP"

echo "== Starting server =="

screen -S minecraft -X quit >/dev/null 2>&1 || true

screen -dmS minecraft bash -c \
"cd '$DIR' && exec java -Xms2G -Xmx3G -jar server.jar nogui"

sleep 5

if screen -list | grep -q '\.minecraft'; then
    echo
    echo "================================"
    echo "SERVER STARTED"
    echo "================================"
    echo "World: Blocked in Combat"
    echo "RAM:   2G-3G"
    echo "Port:  25565"
    echo
    echo "Console:"
    echo "screen -r minecraft"
    echo
    echo "Connect:"
    echo "YOUR_EC2_PUBLIC_IP:25565"
else
    echo
    echo "ERROR: Minecraft did not start."
    echo
    screen -r minecraft || true
    exit 1
fi

