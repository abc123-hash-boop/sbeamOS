#!/usr/bin/env bash
set -Eeuo pipefail

# SbeamOS release identity.
# Keep ID=ubuntu so Ubuntu-specific tools such as add-apt-repository
# continue to recognize the base distribution.
TARGET_BUSINESS_NAME="SbeamOS"
TARGET_BUILD_VERSION="26.04"
TARGET_UBUNTU_VERSION="resolute"
TARGET_NAME="ubuntu"

log() {
  printf '[INFO] %s\n' "$*"
}

log "Updating SbeamOS release identity..."

cat > /etc/lsb-release <<EOF
DISTRIB_ID=${TARGET_BUSINESS_NAME}
DISTRIB_RELEASE=${TARGET_BUILD_VERSION}
DISTRIB_CODENAME=${TARGET_UBUNTU_VERSION}
DISTRIB_DESCRIPTION="${TARGET_BUSINESS_NAME} ${TARGET_BUILD_VERSION}"
EOF

cat > /etc/os-release <<EOF
PRETTY_NAME="${TARGET_BUSINESS_NAME} ${TARGET_BUILD_VERSION}"
NAME="${TARGET_BUSINESS_NAME}"
VERSION_ID="${TARGET_BUILD_VERSION}"
VERSION="${TARGET_BUILD_VERSION} (Resolute Raccoon)"
VERSION_CODENAME=${TARGET_UBUNTU_VERSION}
ID=${TARGET_NAME}
ID_LIKE=ubuntu
UBUNTU_CODENAME=${TARGET_UBUNTU_VERSION}
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
EOF

log "Updating /etc/legal..."
cat > /etc/legal <<EOF

# The programs included with the ${TARGET_BUSINESS_NAME} system are free software;
# the exact distribution terms for each program are described in the
# individual files in /usr/share/doc/*/copyright.

# ${TARGET_BUSINESS_NAME} comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
# applicable law.
EOF

log "SbeamOS branding configuration completed."
