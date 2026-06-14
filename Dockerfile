# Thin layer on top of the official ps2dev image.
#
# The upstream runtime image ships the full PS2 cross-toolchain
# (mips64r5900el-ps2-elf-gcc, ps2sdk, gsKit, env vars) but is a minimal
# Alpine that lacks `make`. We add just enough to drive the toolchain, plus
# xorriso so make_iso.sh can pack a bootable ISO.
FROM ghcr.io/ps2dev/ps2dev:latest

RUN apk add --no-cache make bash xorriso

WORKDIR /src
