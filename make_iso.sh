#!/usr/bin/env bash
#
# Pack a built ps2tech ELF into a bootable PlayStation 2 ISO that PCSX2 (or real
# hardware) can run. Distilled from ps2quake's make_iso.sh — the most built-out
# ISO scaffolding across the source ports — adapted to ps2tech's bin/ layout.
#
# It stages SYSTEM.CNF + the ELF into an ISO9660 tree and runs xorriso
# (mkisofs-compatible) inside the ps2dock toolchain image. SYSTEM.CNF boots
# cdrom0:\PS2MENU.ELF, so whatever ELF you pass is placed on the disc as
# PS2MENU.ELF and one SYSTEM.CNF works for any input.
#
# Usage:
#   ./make_iso.sh                       # pack bin/ps2menu_example.elf -> dist/ps2menu_example.iso
#   ./make_iso.sh bin/foo.elf           # pack any ELF                 -> dist/foo.iso
#   ./make_iso.sh bin/foo.elf data/     # also copy a data dir onto the disc root
#
# Needs xorriso in the toolchain image (see Dockerfile). After changing the
# Dockerfile, rebuild the image once:  docker build -t ps2dock:local .
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="ps2dock:local"

ELF_SRC="${1:-bin/ps2menu_example.elf}"
DATADIR="${2:-}"
[ -f "$ROOT/$ELF_SRC" ] || { echo "!! $ELF_SRC not found -- run ./build.sh first"; exit 1; }

NAME="$(basename "${ELF_SRC%.elf}")"
ISONAME="$NAME.iso"
STAGE="$ROOT/dist/iso"
OUT="$ROOT/dist/$ISONAME"

echo ">> staging ISO tree in dist/iso"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp "$ROOT/SYSTEM.CNF" "$STAGE/SYSTEM.CNF"
cp "$ROOT/$ELF_SRC"   "$STAGE/PS2MENU.ELF"

# Optional data directory (WAD/PAK/etc. the ELF reads via cdfs:) copied onto the
# disc root. For big data, ps2oom instead grafts files in place with
# `mkisofs -graft-points` to skip the staging copy -- swap that in when needed.
if [ -n "$DATADIR" ]; then
    [ -d "$ROOT/$DATADIR" ] || { echo "!! data dir $DATADIR not found"; exit 1; }
    echo ">> staging data from $DATADIR"
    cp -r "$ROOT/$DATADIR/." "$STAGE/"
fi

echo ">> building $OUT"
mkdir -p "$ROOT/dist"
# -iso-level 2 + -l: plain ISO9660 that still allows 8+ char names. PS2 cdvd/cdfs
# read standard ISO9660; cdfs is case-insensitive so lowercase cdfs:/ paths match.
docker run --rm -u "$(id -u):$(id -g)" -v "$ROOT":/work -w /work "$IMAGE" \
    xorriso -as mkisofs -iso-level 2 -l -o "dist/$ISONAME" dist/iso

echo ">> done: $OUT"
ls -la "$OUT"
