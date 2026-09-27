#!/bin/bash
# usage: run.sh <tag>  (runs extracted AppImage in ./squashfs-root, writes logs to ./out)
set -u
tag=$1
root=$PWD/squashfs-root
mkdir -p out
export HOME=$(mktemp -d)
mkdir -p "$HOME/.stellarium/scripts"
cfg=$(find "$root" -name default_cfg.ini | head -1)
cp "$cfg" "$HOME/.stellarium/config.ini"
sed -i '/^\[plugins_load_at_startup\]/a OnlineQueries = true' "$HOME/.stellarium/config.ini"
cat > "$HOME/.stellarium/scripts/t4899.ssc" <<'SSC'
core.wait(5);
OnlineQueries.setEnabled(true);
core.wait(5);
core.selectObjectByName("Mars", true);
OnlineQueries.queryWikipedia();
core.wait(25);
core.quitStellarium();
SSC
cd "$root"
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x1000x24" timeout 150 ./AppRun --startup-script t4899.ssc > "../out/$tag.stdout" 2>&1 &
pid=$!
sleep 45
pgrep -af QtWebEngineProcess > "../out/$tag.pgrep" || echo "no QtWebEngineProcess" > "../out/$tag.pgrep"
wait $pid
echo "exit=$?" > "../out/$tag.exit"
cp "$HOME/.stellarium/log.txt" "../out/$tag.log.txt" 2>/dev/null
cd ..
echo "== $tag: $(cat out/$tag.exit)"
cat "out/$tag.pgrep"
grep -n -i "QtWebEngineProcess\|webengine\|fatal\|OnlineQueries" "out/$tag.stdout" "out/$tag.log.txt" | head -40
