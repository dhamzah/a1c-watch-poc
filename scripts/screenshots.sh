#!/usr/bin/env bash
# Builds the app for the watchOS simulator, installs it, and captures one screenshot per demo screen.
set -euo pipefail
OUT=${OUT:-screenshots}
mkdir -p "$OUT"

# Pick the newest available Apple Watch simulator (prefer a 46mm/45mm Series model).
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
d=json.load(sys.stdin)["devices"]
c=[(rt,x) for rt,xs in d.items() if "watchOS" in rt for x in xs]
c.sort(key=lambda p:(p[0], ("Series" in p[1]["name"]), ("46mm" in p[1]["name"] or "45mm" in p[1]["name"])))
print(c[-1][1]["udid"])')
echo "Simulator: $UDID"

xcodebuild -project A1CWatch.xcodeproj -scheme A1CWatch -configuration Debug \
  -destination "id=$UDID" -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO build 2>&1 | tee build.log | (command -v xcpretty >/dev/null && xcpretty || cat)

APP=$(find build/Build/Products -name "A1CWatch.app" -maxdepth 3 | head -1)
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time "12:41" 2>/dev/null || true

for s in glance rising spike confirm voice recap complications nocgm; do
  xcrun simctl terminate "$UDID" io.a1c.watch.poc 2>/dev/null || true
  xcrun simctl launch "$UDID" io.a1c.watch.poc -screen "$s"
  sleep 6
  xcrun simctl io "$UDID" screenshot "$OUT/$s.png"
  echo "captured $s"
done
