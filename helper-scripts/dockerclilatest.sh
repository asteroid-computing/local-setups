#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


# Usage function for help option
print_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

This script installs and/or updates Docker CLI tools for local development.

Options:
  -p, --install-path PATH   Specify the install path for Docker CLI tools (default: ~/.astrocompute/bin)
  -h, --help                Show this help message and exit
EOF
}

# Parse --install-path/-p and --help/-h options
INSTALL_PATH="$HOME/.astrocompute/bin"
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-path|-p)
            if [[ -n "${2:-}" && ! $2 =~ ^- ]]; then
                INSTALL_PATH="$2"
                shift 2
            else
                echo "Error: --install-path|-p requires a valid path argument." >&2
                exit 1
            fi
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

###################################
# Update Docker CLI
###################################

# Regex for a semver digit
D='0|[1-9][0-9]*'
# Regex for a semver pre-release word
PW='[0-9]*[a-zA-Z-][0-9a-zA-Z-]*'
# Regex for a semver build-metadata word
MW='[0-9a-zA-Z-]+'

GET_DOCKER_CLI_TAGS=$(https -b api.github.com/repos/docker/cli/tags Accept:application/vnd.github+json X-GitHub-Api-Version:2022-11-28 | dasel -r json 'all().name')
DOCKER_CLI_TAGS=($GET_DOCKER_CLI_TAGS)

DOCKER_CLI_LATEST_STABLE=""

for ver in "${DOCKER_CLI_TAGS[@]}"; do
    cleanVer=$(echo $ver | tr -d '"v')
    if [[ "$cleanVer" =~ ^($D)\.($D)\.($D)(-(($D|$PW)(\.($D|$PW))*))?(\+($MW(\.$MW)*))?$ ]]; then
        if [[ "${BASH_REMATCH[5]:-""}" == "" ]]; then
            DOCKER_CLI_LATEST_STABLE="$cleanVer"
            break
        fi
    fi
done

# Check if docker command is available
if ! command -v docker >/dev/null 2>&1; then
    CURRENT_CLIENT_VERSION="0.0.0"
else
    CURRENT_CLIENT_VERSION=$(docker version --format json | dasel -r json 'Client.Version' | tr -d '"')
fi

echo "Latest Docker CLI Tag: $DOCKER_CLI_LATEST_STABLE"
echo "Current Docker CLI Version: $CURRENT_CLIENT_VERSION"

if [ "$DOCKER_CLI_LATEST_STABLE" != "$CURRENT_CLIENT_VERSION" ]; then
    echo ""
    echo "Updating Docker CLI..."

    TEMP_DIR="$(mktemp -d -p ${INSTALL_PATH})"

    cd ${TEMP_DIR}

    curl -LO https://download.docker.com/mac/static/stable/aarch64/docker-${DOCKER_CLI_LATEST_STABLE}.tgz
    tar -xvf docker-${DOCKER_CLI_LATEST_STABLE}.tgz
    rm -f "${INSTALL_PATH}/docker"
    mv docker/docker "${INSTALL_PATH}/docker"
    cd -
    rm -rf ${TEMP_DIR}
else
    echo "Docker CLI is up to date."
    echo ""
fi

###################################
# Update Docker BuildX Plugin
###################################

LATEST_BUILDX_TAG=$(https -b api.github.com/repos/docker/buildx/releases/latest Accept:application/vnd.github+json X-GitHub-Api-Version:2022-11-28 | dasel -r json 'tag_name' | tr -d '"v')

# Check if docker buildx is available
if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
    BUILDX_VERSION_STR=$(docker buildx version)
else
    BUILDX_VERSION_STR="github.com/docker/buildx v0.0.0 not_installed"
fi

IFS=' '
CURRENT_BUILDX_VERSION=($BUILDX_VERSION_STR)
if [[ ${#CURRENT_BUILDX_VERSION[@]} -gt 1 ]]; then
    CURRENT_BUILDX_VERSION=${CURRENT_BUILDX_VERSION[1]}
    CURRENT_BUILDX_VERSION=$(echo $CURRENT_BUILDX_VERSION | tr -d 'v')
else
    CURRENT_BUILDX_VERSION="0.0.0"
fi
IFS=$'\n\t'
echo "Latest buildx tag: $LATEST_BUILDX_TAG"
echo "Current buildx version: $CURRENT_BUILDX_VERSION"

if [ "$LATEST_BUILDX_TAG" != "$CURRENT_BUILDX_VERSION" ]; then
    echo ""
    echo "Updating buildx..."

    mkdir -p ~/.docker/cli-plugins

    TEMP_DIR="$(mktemp -d -p ${INSTALL_PATH})"

    cd ${TEMP_DIR}

    curl -LO https://github.com/docker/buildx/releases/download/v${LATEST_BUILDX_TAG}/buildx-v${LATEST_BUILDX_TAG}.darwin-arm64
    rm ~/.docker/cli-plugins/docker-buildx
    mv buildx-v${LATEST_BUILDX_TAG}.darwin-arm64 ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    cd -
    rm -rf ${TEMP_DIR}
    echo "Buildx updated successfully."
else
    echo "buildx is up to date."
    echo ""
fi

###################################
# Update Docker MacOS Credentials Helper
###################################

LATEST_DOCKERMACOSCREDS_TAG=$(https -b api.github.com/repos/docker/docker-credential-helpers/releases/latest Accept:application/vnd.github+json X-GitHub-Api-Version:2022-11-28 | dasel -r json 'tag_name' | tr -d '"v')

# Check if docker-credential-osxkeychain command is available
if command -v docker-credential-osxkeychain >/dev/null 2>&1; then
    DOCKERMACOSCREDS_VERSION_STR=$(docker-credential-osxkeychain --version)
else
    DOCKERMACOSCREDS_VERSION_STR="docker-credential-osxkeychain (github.com/docker/docker-credential-helpers) v0.0.0"
fi

IFS=' '
CURRENT_DOCKERMACOSCREDS_VERSION=($DOCKERMACOSCREDS_VERSION_STR)
CURRENT_DOCKERMACOSCREDS_VERSION=${CURRENT_DOCKERMACOSCREDS_VERSION[2]}
CURRENT_DOCKERMACOSCREDS_VERSION=$(echo $CURRENT_DOCKERMACOSCREDS_VERSION | tr -d 'v')

IFS=$'\n\t'
echo "Latest docker-credential-helpers tag: $LATEST_DOCKERMACOSCREDS_TAG"
echo "Current docker-credential-helpers version: $CURRENT_DOCKERMACOSCREDS_VERSION"

if [ "$LATEST_DOCKERMACOSCREDS_TAG" != "$CURRENT_DOCKERMACOSCREDS_VERSION" ]; then
    echo ""
    echo "Updating docker-credential-helpers..."

    TEMP_DIR="$(mktemp -d -p ${INSTALL_PATH})"

    cd ${TEMP_DIR}

    curl -LO https://github.com/docker/docker-credential-helpers/releases/download/v${LATEST_DOCKERMACOSCREDS_TAG}/docker-credential-osxkeychain-v${LATEST_DOCKERMACOSCREDS_TAG}.darwin-arm64
    rm -f "${INSTALL_PATH}/docker-credential-osxkeychain"

    mv docker-credential-osxkeychain-v${LATEST_DOCKERMACOSCREDS_TAG}.darwin-arm64 ${INSTALL_PATH}/docker-credential-osxkeychain
    chmod +x ${INSTALL_PATH}/docker-credential-osxkeychain
    cd -
    rm -rf ${TEMP_DIR}
    echo "docker-credential-helpers updated successfully."
else
    echo "docker-credential-helpers is up to date."
    echo ""
fi

###################################
# Update Docker Compose Plugin
###################################

LATEST_DOCKERCOMPOSE_TAG=$(https -b api.github.com/repos/docker/compose/releases/latest Accept:application/vnd.github+json X-GitHub-Api-Version:2022-11-28 | dasel -r json 'tag_name' | tr -d '"v')

# Check if docker compose subcommand is available
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_VERSION_STR=$(docker compose version)
else
    DOCKER_COMPOSE_VERSION_STR="Docker Compose version v0.0.0"
fi

IFS=' '
CURRENT_DOCKER_COMPOSE_VERSION=($DOCKER_COMPOSE_VERSION_STR)
CURRENT_DOCKER_COMPOSE_VERSION=${CURRENT_DOCKER_COMPOSE_VERSION[3]}
CURRENT_DOCKER_COMPOSE_VERSION=$(echo $CURRENT_DOCKER_COMPOSE_VERSION | tr -d 'v')

IFS=$'\n\t'
echo "Latest docker-compose tag: $LATEST_DOCKERCOMPOSE_TAG"
echo "Current docker-compose version: $CURRENT_DOCKER_COMPOSE_VERSION"

if [ "$LATEST_DOCKERCOMPOSE_TAG" != "$CURRENT_DOCKER_COMPOSE_VERSION" ]; then
    echo ""
    echo "Updating docker-compose..."

    TEMP_DIR="$(mktemp -d -p ${INSTALL_PATH})"
    cd ${TEMP_DIR}
    
    mkdir -p ~/.docker/cli-plugins

    curl -LO https://github.com/docker/compose/releases/download/v${LATEST_DOCKERCOMPOSE_TAG}/docker-compose-darwin-aarch64
    rm -f ~/.docker/cli-plugins/docker-compose
    mv docker-compose-darwin-aarch64 ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
    cd -
    rm -rf ${TEMP_DIR}
    echo "docker-compose updated successfully."
else
    echo "docker-compose is up to date."
    echo ""
fi
