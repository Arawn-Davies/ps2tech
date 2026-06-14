#!/usr/bin/env bash
#
# Build the project inside the ps2dock container (official ps2dev
# toolchain + make, see Dockerfile).
#
# Sources live in src/, intermediate objects in obj/, final ELFs in bin/.
#
# Usage:
#   ./build.sh            # runs `make` (src/ -> obj/ -> bin/)
#   ./build.sh clean      # removes obj/ and bin/
#   ./build.sh shell      # opens an interactive shell in the container
#
set -euo pipefail

IMAGE="ps2dock:local"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build the local image if it doesn't exist yet.
if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo ">> building ${IMAGE} ..."
  docker build -t "${IMAGE}" "${HERE}"
fi

# Mount the whole project at /work and run as the host user so build
# artifacts aren't owned by root.
common=(--rm -u "$(id -u):$(id -g)" -v "${HERE}:/work" -w /work)

if [[ "${1:-}" == "shell" ]]; then
  exec docker run -it "${common[@]}" "${IMAGE}" /bin/bash
fi

# Pass all args straight to make (defaults to the `all` target).
exec docker run "${common[@]}" "${IMAGE}" make "$@"
