#!/bin/sh
# install.sh — install qdata into ~/.local (no root needed).
#
#   curl -fsSL https://cuiqanalytics.github.io/qdata/install.sh | sh
#
# Re-running it replaces the previous install (upgrade in place). QDATA_URL overrides the
# download location (a file:// URL works too, for testing a local build).
set -eu

repo="cuiqanalytics/qdata"
lib_dir="${HOME}/.local/lib/qdata"
bin_dir="${HOME}/.local/bin"
url="${QDATA_URL:-https://github.com/${repo}/releases/latest/download/qdata-cli-linux-x86_64.tar.gz}"

case "$(uname -s)/$(uname -m)" in
	Linux/x86_64) ;;
	*) echo "qdata ships a Linux x86_64 binary only. On macOS/Windows use Docker:"
	   echo "  docker pull ghcr.io/${repo}"
	   exit 1 ;;
esac

echo "Downloading ${url}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 --retry-delay 2 "$url" | tar xz -C "$tmp"

rm -rf "$lib_dir"
mkdir -p "$(dirname "$lib_dir")"
mv "$tmp/qdata-cli-linux-x86_64" "$lib_dir"

mkdir -p "$bin_dir"
ln -sf "$lib_dir/qdata" "$bin_dir/qdata"

echo "Installed to $lib_dir"
echo "Linked $bin_dir/qdata -> $lib_dir/qdata"

case ":$PATH:" in
	*":$bin_dir:"*) ;;
	*) echo "Add $bin_dir to your PATH (e.g. in ~/.bashrc): export PATH=\"$bin_dir:\$PATH\"" ;;
esac

"$bin_dir/qdata" --version
