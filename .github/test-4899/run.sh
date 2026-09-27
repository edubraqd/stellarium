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
QT_DEBUG_PLUGINS=1 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1024x768x24" timeout 540 ./AppRun --startup-script t4899.ssc > "../out/$tag.stdout" 2>&1 &
pid=$!
t=0
echo "no QtWebEngineProcess" > "../out/$tag.pgrep"
while kill -0 $pid 2>/dev/null; do
  if pgrep -af QtWebEngineProcess > /tmp/pg; then echo "t=${t}s"; cat /tmp/pg; fi > "../out/$tag.pgrep.tmp"
  [ -s "../out/$tag.pgrep.tmp" ] && mv "../out/$tag.pgrep.tmp" "../out/$tag.pgrep"
  [ $((t % 60)) -eq 0 ] && echo "t=${t}s last log: $(tail -1 ../out/$tag.stdout | cut -c1-150)"
  sleep 5; t=$((t+5))
done
wait $pid
echo "exit=$?" > "../out/$tag.exit"
cp "$HOME/.stellarium/log.txt" "../out/$tag.log.txt" 2>/dev/null
cd ..
echo "== $tag: $(cat out/$tag.exit)"
cat "out/$tag.pgrep"
grep -n -i "QtWebEngineProcess\|webengine\|fatal\|OnlineQueries" "out/$tag.stdout" "out/$tag.log.txt" | head -40
