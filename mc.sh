```bash
#!/bin/bash
set -e

DIR="/opt/minecraft"
JAR="$DIR/server.jar"
MAP="/tmp/blocked.zip"

echo "Installing..."

apt-get update -y
apt-get install -y openjdk-21-jre-headless curl unzip screen

mkdir -p "$DIR"

echo "Downloading Minecraft..."

curl -fL \
  "https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar" \
  -o "$JAR"

echo "Downloading Blocked in Combat..."

curl -fL \
  "https://edge.forgecdn.net/files/7695/831/Blocked%20in%20Combat%20-%20Remastered_v1.0.2-1.21.11.zip" \
  -o "$MAP"

echo "Checking map..."

unzip -t "$MAP" >/dev/null

rm -rf /tmp/blocked
mkdir -p /tmp/blocked

unzip -q "$MAP" -d /tmp/blocked

WORLD=$(find /tmp/blocked -type f -name level.dat -printf '%h\n' | head -n 1)

if [ -z "$WORLD" ]; then
    echo "ERROR: level.dat not found."
    exit 1
fi

echo "Installing world..."

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

echo "Starting server..."

screen -S minecraft -dm bash -c \
  "cd '$DIR' && exec java -Xms2G -Xmx3G -jar server.jar nogui"

sleep 3

if screen -list | grep -q minecraft; then
    echo
    echo "================================"
    echo " SERVER RUNNING"
    echo "================================"
    echo
    echo "Port: 25565"
    echo "RAM: 2G-3G"
    echo
    echo "Connect with:"
    echo "YOUR_EC2_PUBLIC_IP:25565"
    echo
    echo "Console:"
    echo "screen -r minecraft"
else
    echo "ERROR: Server failed to start."
    exit 1
fi
```
