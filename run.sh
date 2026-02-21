#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

APP_NAME="spotcast"
APP_DISPLAY_NAME="Spotcast"
APP_BUNDLE=".build/${APP_DISPLAY_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

if [ -t 1 ] && [ "${NO_COLOR:-}" != "1" ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
else
    C_RESET=""
    C_BOLD=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_CYAN=""
fi

STEP_SYMBOL="->"
OK_SYMBOL="[OK]"
WARN_SYMBOL="[!]"
ERR_SYMBOL="[x]"

if [ -t 1 ]; then
    STEP_SYMBOL="=>"
    OK_SYMBOL="✓"
    WARN_SYMBOL="⚠"
    ERR_SYMBOL="✗"
fi

log_step() {
    printf "%b%s%b %s\n" "${C_CYAN}${C_BOLD}" "${STEP_SYMBOL}" "${C_RESET}" "$1"
}

log_ok() {
    printf "%b%s%b %s\n" "${C_GREEN}${C_BOLD}" "${OK_SYMBOL}" "${C_RESET}" "$1"
}

log_warn() {
    printf "%b%s%b %s\n" "${C_YELLOW}${C_BOLD}" "${WARN_SYMBOL}" "${C_RESET}" "$1" >&2
}

log_error() {
    printf "%b%s%b %s\n" "${C_RED}${C_BOLD}" "${ERR_SYMBOL}" "${C_RESET}" "$1" >&2
}

require_command() {
    if ! command -v "$1" > /dev/null 2>&1; then
        log_error "Required command not found: $1"
        exit 1
    fi
}

cleanup() {
    :
}
trap cleanup EXIT

require_command swift
require_command open

printf "%b=== Running %s (dev app bundle) ===%b\n" "${C_BOLD}${C_BLUE}" "${APP_DISPLAY_NAME}" "${C_RESET}"
log_step "Building ${APP_DISPLAY_NAME}..."
swift build

BIN_PATH="$(swift build --show-bin-path)/${APP_NAME}"
if [ ! -x "${BIN_PATH}" ]; then
    log_error "Built binary not found at ${BIN_PATH}"
    exit 1
fi

mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_DISPLAY_NAME}"

log_step "Writing Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_DISPLAY_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.spotcast</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.0-dev</string>
    <key>CFBundleVersion</key>
    <string>0.0.0-dev</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

log_step "Opening ${APP_BUNDLE}..."
open "${APP_BUNDLE}"
log_ok "App opened."
