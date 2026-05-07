#!/usr/bin/env sh
# check-esbuild.sh
# Diagnostic helper to inspect a frontend image for esbuild/node architecture and binary issues.
# Usage: ./scripts/check-esbuild.sh [IMAGE]
# Example: ./scripts/check-esbuild.sh ghcr.io/open-platforms-org/ministack-ui-frontend:latest

set -eu
IMAGE=${1:-${DOCKER_IMAGE:-local/ministack-ui-frontend:local}}

echo "Checking image: $IMAGE"

# detect runtime (podman or docker)
if command -v podman >/dev/null 2>&1; then
  RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
  RUNTIME=docker
else
  echo "Error: neither podman nor docker CLI found in PATH." >&2
  exit 2
fi

echo "Using runtime: $RUNTIME"

# helper to run a command using the runtime
run_container() {
  if [ "$RUNTIME" = "podman" ]; then
    podman run --rm -it --entrypoint sh "$IMAGE" -c "$1"
  else
    docker run --rm -it --entrypoint sh "$IMAGE" -c "$1"
  fi
}

# try to inspect manifest (if buildx/imagetools installed for docker; podman may not support it)
if command -v docker >/dev/null 2>&1; then
  # check whether docker buildx is available
  if docker buildx version >/dev/null 2>&1; then
    echo "Attempting to inspect manifest with buildx imagetools (docker buildx available)"
    docker buildx imagetools inspect "$IMAGE" || true
  else
    echo "Docker found but buildx not available; skipping imagetools inspect."
  fi
else
  echo "Skipping buildx imagetools inspect (docker not available)."
fi

# Try podman/docker image inspect for arch info
echo "Image inspect (platform):"
if [ "$RUNTIME" = "podman" ]; then
  podman image inspect "$IMAGE" --format '{{.RepoTags}} {{.Architecture}}/{{.Os}}/{{.Variant}}' || podman image inspect "$IMAGE" || true
else
  docker image inspect "$IMAGE" --format '{{range .RepoTags}}{{.}} {{end}} {{.Os}}/{{.Architecture}}/{{.Variant}}' || docker image inspect "$IMAGE" || true
fi

# Run checks inside container
echo
echo "Running runtime checks inside a temporary container..."
COMMAND="uname -a; echo; echo 'node process.arch:'; node -e 'console.log(process.arch)'; echo; echo 'node version:'; node -v; echo; echo 'esbuild check (require):'; node -e \"try{console.log(require('esbuild').version)}catch(e){console.error('esbuild require failed:', e && e.message); process.exit(0)}\"; echo; echo 'ls esbuild bin:'; ls -la node_modules/esbuild/bin || true; echo; echo 'file esbuild binary (if file exists):'; if command -v file >/dev/null 2>&1; then file node_modules/esbuild/bin/esbuild || true; else echo 'file command not available in container'; fi; echo; echo 'test simple esbuild transform:'; node -e \"const esbuild=require('esbuild');esbuild.transform('let a=1',{loader:'ts'}).then(r=>console.log('transform ok')).catch(e=>{console.error('transform failed:',e && e.message);process.exit(1)})\""

# Use a single run invocation - it will print outputs
if [ "$RUNTIME" = "podman" ]; then
  podman run --rm --entrypoint sh "$IMAGE" -c "$COMMAND" || true
else
  docker run --rm --entrypoint sh "$IMAGE" -c "$COMMAND" || true
fi

# Final recommendations
cat <<EOF

Recommendations (based on results you saw above):
- If the 'file' output shows x86-64 but node reports arm64: the esbuild binary is amd64 in an arm container. Rebuild the image for arm64 or publish a multi-arch image.
- To build multi-arch locally: use Docker Buildx:
  docker buildx build --platform linux/amd64,linux/arm64 -t YOURUSER/ministack-ui-frontend:latest --push ./frontend
- To test an arm build locally on M1/M2:
  docker buildx build --platform linux/arm64 -t local/ministack-ui-frontend:local --load ./frontend
- If you use Podman: try building with --arch arm64 or use Docker Desktop if you prefer the Docker buildx workflow.
- If you see 'Killed' or 'OOM' in logs, increase Docker/Podman VM memory.

EOF

exit 0

