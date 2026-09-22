```bash
#!/bin/bash
set -e

# ============================================================
# Minecraft 1.21.11 Vanilla
# Blocked in Combat | Remastered v1.0.2
# Ubuntu EC2 t3.medium
# ZERO INTERACTION```bash
#!/bin/bash

set -e

DIR="/opt/minecraft"
JAR="$DIR/server.jar"
MAP="/tmp/map.zip"

apt update -y
apt install -y openjdk-21-jre-headless curl unzip screen

mkdir -p "$DIR"

curl -L \
  "https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar" \
  -o "$JAR"

curl -L \
  "https://www.curseforge.com/minecraft/worlds/blocked-in-combat-remastered/download/7695831" \
  -o "$MAP"

rm -rf /tmp/map
mkdir /tmp/map
unzip -q "$MAP" -d /tmp/map

WORLD=$(find /tmp/map -type f -name level.dat -printf '%h\n' | head -n 1)

rm -rf "$DIR/world"
cp -r "$WORLD" "$DIR/world"

cat > "$DIR/eula.txt" <<EOF
eula=true
EOF

cat > "$DIR/server.properties" <<EOF
level-name=world
server-port=25565
gamemode=adventure
difficulty=normal
max-players=8
view-distance=8
simulation-distance=6
spawn-protection=0
online-mode=true
motd=Blocked in Combat | Remastered
EOF

screen -S minecraft -dm bash -c \
  "cd $DIR && java -Xms2G -Xmx3G -jar server.jar nogui"

echo
echo "Minecraft server started."
echo "Connect: YOUR_EC2_IP:25565"
echo
echo "Console: screen -r minecraft"
```

# ============================================================

MC_DIR="/opt/minecraft"
MC_USER="minecraft"
WORLD_NAME="world"

SERVER_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
MAP_URL="https://www.curseforge.com/minecraft/worlds/blocked-in-combat-remastered/download/7695831"

echo "=== Installing Minecraft 1.21.11 ==="

# Must be root
if [ "$EUID" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y \
    openjdk-21-jre-headless \
    curl \
    ca-certificates \
    unzip \
    ufw

# ------------------------------------------------------------
# Minecraft user
# ------------------------------------------------------------

if ! id "$MC_USER" >/dev/null 2>&1; then
    useradd \
        --system \
        --create-home \
        --home-dir "$MC_DIR" \
        --shell /usr/sbin/nologin \
        "$MC_USER"
fi

mkdir -p "$MC_DIR"
chown -R "$MC_USER:$MC_USER" "$MC_DIR"

# ------------------------------------------------------------
# Server JAR
# ------------------------------------------------------------

echo "=== Downloading Minecraft server ==="

curl -fL \
    --retry 5 \
    --retry-delay 2 \
    "$SERVER_URL" \
    -o "$MC_DIR/server.jar"

# ------------------------------------------------------------
# Download map
# ------------------------------------------------------------

echo "=== Downloading Blocked in Combat ==="

rm -rf /tmp/blocked-map
mkdir -p /tmp/blocked-map

curl -fL \
    --retry 5 \
    --retry-delay 2 \
    -A "Mozilla/5.0" \
    "$MAP_URL" \
    -o /tmp/blocked-map.zip

unzip -q /tmp/blocked-map.zip -d /tmp/blocked-map

# Find actual Minecraft world directory
WORLD_DIR=""

while IFS= read -r level; do
    CANDIDATE="$(dirname "$level")"

    if [ -f "$CANDIDATE/level.dat" ]; then
        WORLD_DIR="$CANDIDATE"
        break
    fi
done < <(find /tmp/blocked-map -type f -name "level.dat")

if [ -z "$WORLD_DIR" ]; then
    echo "ERROR: level.dat was not found."
    exit 1
fi

# ------------------------------------------------------------
# Install world
# ------------------------------------------------------------

rm -rf "$MC_DIR/$WORLD_NAME"
cp -a "$WORLD_DIR" "$MC_DIR/$WORLD_NAME"

# ------------------------------------------------------------
# EULA
# ------------------------------------------------------------

cat > "$MC_DIR/eula.txt" <<EOF
eula=true
EOF

# ------------------------------------------------------------
# Server properties
# ------------------------------------------------------------

cat > "$MC_DIR/server.properties" <<EOF
allow-flight=false
allow-nether=true
difficulty=normal
enable-command-block=true
enable-query=false
enable-rcon=false
enforce-secure-profile=true
gamemode=adventure
hardcore=false
level-name=world
max-players=8
motd=Blocked in Combat | Remastered
online-mode=true
pvp=true
server-ip=
server-port=25565
simulation-distance=6
spawn-protection=0
view-distance=8
white-list=false
EOF

# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------

chown -R "$MC_USER:$MC_USER" "$MC_DIR"

# ------------------------------------------------------------
# systemd service
# ------------------------------------------------------------

cat > /etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=Minecraft 1.21.11 Vanilla Server
After=network-online.target
Wants=network-online.target

[Service]
User=$MC_USER
Group=$MC_USER
WorkingDirectory=$MC_DIR

ExecStart=/usr/bin/java -Xms2G -Xmx3G -jar $MC_DIR/server.jar nogui

Restart=on-failure
RestartSec=10

TimeoutStopSec=60
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

# ------------------------------------------------------------
# Firewall
# ------------------------------------------------------------

ufw allow 25565/tcp >/dev/null 2>&1 || true

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------

systemctl daemon-reload
systemctl enable minecraft
systemctl start minecraft

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

rm -rf /tmp/blocked-map /tmp/blocked-map.zip

echo
echo "=========================================="
echo " Minecraft server is RUNNING"
echo "=========================================="
echo
echo "Version : 1.21.11"
echo "Map     : Blocked in Combat | Remastered"
echo "RAM     : 2G-3G"
echo "Port    : 25565"
echo
echo "Connect with:"
echo "YOUR_EC2_PUBLIC_IP:25565"
echo
echo "=========================================="
```
