#!/bin/bash
set -euo pipefail

# Configuration
UPSTREAM_REPO="sigoden/aichat"
UPSTREAM_BRANCH="main"
SPEC_FILE="aichat-git.spec"
OUTDIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==== COPR Build - AIChat Git Snapshot ===="
echo ""

# Install dependencies
echo "-> Installing dependencies..."
dnf install -y git curl jq rpm-build rpmdevtools
echo ""

# Fetch latest commit from GitHub API
echo "-> Fetching latest commit from ${UPSTREAM_REPO}..."
COMMIT_JSON=$(curl -s "https://api.github.com/repos/${UPSTREAM_REPO}/commits/${UPSTREAM_BRANCH}")
COMMIT_SHA=$(echo "$COMMIT_JSON" | jq -r '.sha')
SHORT_SHA=$(echo "$COMMIT_SHA" | cut -c1-7)
COMMIT_DATE=$(echo "$COMMIT_JSON" | jq -r '.commit.committer.date' | cut -d'T' -f1 | tr -d '-')

echo "  Latest commit: ${COMMIT_SHA}"
echo "  Short SHA: ${SHORT_SHA}"
echo "  Commit date: ${COMMIT_DATE}"
echo ""

# Check if this is a new commit (abort if no change)
LAST_BUILD_FILE="${PROJECT_DIR}/.last_build_commit"
if [ -f "$LAST_BUILD_FILE" ]; then
    LAST_COMMIT=$(cat "$LAST_BUILD_FILE")
    if [ "$LAST_COMMIT" = "$COMMIT_SHA" ]; then
        echo "X No new commit detected. Aborting build."
        echo "  Last built commit: $LAST_COMMIT"
        exit 1
    fi
fi
echo "OK New commit detected, proceeding with build"
echo ""

# Clone upstream repository
echo "-> Cloning upstream repository..."
rm -rf /tmp/aichat-build
git clone --depth=1 --branch="${UPSTREAM_BRANCH}" "https://github.com/${UPSTREAM_REPO}.git" /tmp/aichat-build
echo ""

# Extract version from Cargo.toml
echo "-> Extracting version from Cargo.toml..."
UPSTREAM_VERSION=$(grep '^version = ' /tmp/aichat-build/Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
echo "  Upstream version: ${UPSTREAM_VERSION}"
echo ""

# Create source tarball
echo "-> Creating source tarball..."
cd /tmp
tar czf "aichat-${SHORT_SHA}.tar.gz" \
    --exclude=.git \
    --transform "s,^aichat-build,aichat-${COMMIT_SHA}," \
    aichat-build/
echo "  Created: aichat-${SHORT_SHA}.tar.gz"
echo ""

# Prepare RPM build environment
echo "-> Preparing RPM build environment..."
mkdir -p "$OUTDIR"
mkdir -p /tmp/rpmbuild/{SOURCES,SPECS,SRPMS}
cp "/tmp/aichat-${SHORT_SHA}.tar.gz" /tmp/rpmbuild/SOURCES/
cp "${PROJECT_DIR}/${SPEC_FILE}" /tmp/rpmbuild/SPECS/
echo ""

# Build SRPM
echo "-> Building SRPM..."
rpmbuild -bs "/tmp/rpmbuild/SPECS/${SPEC_FILE}" \
    --define "_topdir /tmp/rpmbuild" \
    --define "_srcrpmdir ${OUTDIR}" \
    --define "commit0 ${COMMIT_SHA}" \
    --define "shortcommit0 ${SHORT_SHA}" \
    --define "commitdate ${COMMIT_DATE}" \
    --define "upstream_version ${UPSTREAM_VERSION}"
echo ""

# Save commit SHA for next build
echo "$COMMIT_SHA" > "$LAST_BUILD_FILE"

echo "==== Build Complete ===="
ls -lh "${OUTDIR}"/*.src.rpm
