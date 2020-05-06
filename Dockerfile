FROM debian:10.3

ENTRYPOINT "${GITHUB_WORKSPACE}/scripts/docker/entrypoint.sh"
