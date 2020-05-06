FROM ubuntu:20.04

ENTRYPOINT "${GITHUB_WORKSPACE}/scripts/docker/entrypoint.sh"
