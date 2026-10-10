#!/usr/bin/env bash
# release.sh — build dist/qdata-cli-linux-x86_64.tar.gz, the tarball install.sh and the
# Dockerfile download. Upload it to a GitHub release of cuiqanalytics/qdata.
#
#   ./release.sh              build from source, then package
#   ./release.sh --no-build   package the binary already in $QDATA_SRC
#
# The DuckDB extensions are installed with the staged binary, which runs as Pro only when a
# license is installed on this machine; without one only the free-tier set gets bundled.
set -euo pipefail
cd "$(dirname "$0")"

SRC=${QDATA_SRC:-../cuiqData/src}
LIBDUCKDB=${LIBDUCKDB:-../vduckdb/src/thirdparty/libduckdb.so}
LIBSQLITE=${LIBSQLITE:-/usr/local/lib/libsqlite3.so}
EXTENSIONS=${EXTENSIONS:-"webbed parser_tools excel mysql postgres httpfs json icu"}
NAME=qdata-cli-linux-x86_64
OUT=dist/$NAME

version=$(cat VERSION)
src_version=$(sed -n "s/.*version: *'\([^']*\)'.*/\1/p" "$SRC/../v.mod")
[[ "$version" == "$src_version" ]] || { echo "error: VERSION ($version) != v.mod ($src_version)" >&2; exit 1; }

[[ "${1:-}" == --no-build ]] || make -C "$SRC" prod
[[ -x "$SRC/qdata" ]] || { echo "error: $SRC/qdata not found" >&2; exit 1; }
[[ -f "$LIBDUCKDB" ]] || { echo "error: libduckdb.so not found at $LIBDUCKDB" >&2; exit 1; }
[[ -f "$LIBSQLITE" ]] || { echo "error: libsqlite3.so not found at $LIBSQLITE" >&2; exit 1; }

rm -rf "$OUT" && mkdir -p "$OUT/bin" "$OUT/extensions"
cp "$SRC/qdata" "$OUT/bin/qdata"
cp "$LIBDUCKDB" "$OUT/bin/libduckdb.so"
# The binary links libsqlite3.so by that exact name; ship it so no system package is needed.
cp -L "$LIBSQLITE" "$OUT/bin/libsqlite3.so"
python3 -c "import ctypes,sys; l=ctypes.CDLL(sys.argv[1]); l.duckdb_library_version.restype=ctypes.c_char_p; print(l.duckdb_library_version().decode())" \
  "$OUT/bin/libduckdb.so" > "$OUT/bin/DUCKDB_VERSION"

cat > "$OUT/qdata" <<'LAUNCHER'
#!/bin/sh
self=$(readlink -f "$0")
dir=$(dirname "$self")
LIBDUCKDB_DIR="$dir/bin" LD_LIBRARY_PATH="$dir/bin${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" exec "$dir/bin/qdata" "$@"
LAUNCHER
chmod +x "$OUT/qdata" "$OUT/bin/qdata"

# Pre-install extensions so installs work offline and extension versions are pinned to this
# release. The binary picks up <install>/extensions automatically.
install_sql=""
for ext in $EXTENSIONS; do
  case "$ext" in
    webbed|parser_tools) install_sql+="INSTALL $ext FROM community; " ;;
    *) install_sql+="INSTALL $ext; " ;;
  esac
done
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
(cd "$work" && "$OLDPWD/$OUT/qdata" exec "$install_sql SELECT extension_name FROM duckdb_extensions() WHERE installed ORDER BY 1")
[[ -n "$(find "$OUT/extensions" -name 'webbed.duckdb_extension')" ]] || { echo "error: webbed was not bundled" >&2; exit 1; }

# Skill references come from the embedded docs, so the skill matches this binary.
for doc in STEPS CONFIG TEMPLATING; do
  cp "$SRC/templates/$doc.md" "skills/qdata/references/$(echo "$doc" | tr '[:upper:]' '[:lower:]').md"
done

cp -R skills examples install-skills.sh install-skills.ps1 README.md QUICK_REFERENCE.md LICENSE VERSION "$OUT/"

tar -C dist -czf "dist/$NAME.tar.gz" "$NAME"
rm -rf "$OUT"
ls -la "dist/$NAME.tar.gz"
sha256sum "dist/$NAME.tar.gz"
