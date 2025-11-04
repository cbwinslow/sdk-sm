#!/usr/bin/env bash
# Simple script to download all Bitwarden repositories from GitHub
# This version uses curl to fetch repo list and doesn't require gh CLI
# Usage: ./download-bitwarden-repos-simple.sh [target_directory]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get target directory from argument or use current directory
TARGET_DIR="${1:-.}"
OWNER="bitwarden"
API_URL="https://api.github.com/orgs/${OWNER}/repos"

echo -e "${GREEN}Bitwarden Repository Downloader (Simple Version)${NC}"
echo "======================================"
echo "This script will clone all public repositories from the ${OWNER} GitHub organization."
echo "Target directory: ${TARGET_DIR}"
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed.${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    echo "Please install jq from: https://stedolan.github.io/jq/"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}"

echo "Fetching list of repositories..."

# Fetch all repositories from the organization (with pagination)
REPOS=""
PAGE=1
PER_PAGE=100

while true; do
    echo "  Fetching page ${PAGE}..."
    RESPONSE=$(curl -s "${API_URL}?per_page=${PER_PAGE}&page=${PAGE}")
    
    # Check if we got valid JSON
    if ! echo "$RESPONSE" | jq empty 2>/dev/null; then
        echo -e "${RED}Error: Failed to fetch repository list from GitHub API.${NC}"
        echo "Response: $RESPONSE"
        exit 1
    fi
    
    # Extract clone URLs
    PAGE_REPOS=$(echo "$RESPONSE" | jq -r '.[].clone_url')
    
    # Break if no more repos
    if [ -z "$PAGE_REPOS" ]; then
        break
    fi
    
    REPOS="${REPOS}${PAGE_REPOS}"$'\n'
    PAGE=$((PAGE + 1))
    
    # Check if this was the last page
    REPO_COUNT=$(echo "$RESPONSE" | jq '. | length')
    if [ "$REPO_COUNT" -lt "$PER_PAGE" ]; then
        break
    fi
done

# Remove trailing newline
REPOS=$(echo "$REPOS" | sed '/^$/d')

if [ -z "$REPOS" ]; then
    echo -e "${RED}Error: No repositories found or failed to fetch repository list.${NC}"
    exit 1
fi

# Count total repos
TOTAL=$(echo "$REPOS" | wc -l)
CURRENT=0
CLONED=0
UPDATED=0
FAILED=0

echo "Found ${TOTAL} repositories."
echo ""

# Clone or update each repository
while IFS= read -r repo_url; do
    [ -z "$repo_url" ] && continue
    
    CURRENT=$((CURRENT + 1))
    
    # Extract repo name from URL
    REPO_NAME=$(basename "$repo_url" .git)
    
    echo -e "${GREEN}[${CURRENT}/${TOTAL}]${NC} Processing ${REPO_NAME}..."
    
    if [ -d "${REPO_NAME}" ]; then
        echo "  Repository already exists. Updating..."
        if (cd "${REPO_NAME}" && git pull --ff-only); then
            UPDATED=$((UPDATED + 1))
            echo -e "  ${GREEN}✓ Updated${NC}"
        else
            FAILED=$((FAILED + 1))
            echo -e "  ${RED}✗ Failed to update${NC}"
        fi
    else
        echo "  Cloning..."
        if git clone "${repo_url}" "${REPO_NAME}"; then
            CLONED=$((CLONED + 1))
            echo -e "  ${GREEN}✓ Cloned${NC}"
        else
            FAILED=$((FAILED + 1))
            echo -e "  ${RED}✗ Failed to clone${NC}"
        fi
    fi
    echo ""
done <<< "$REPOS"

# Summary
echo "======================================"
echo -e "${GREEN}Download Complete!${NC}"
echo "======================================"
echo "Total repositories: ${TOTAL}"
echo "Newly cloned:       ${CLONED}"
echo "Updated:            ${UPDATED}"
echo "Failed:             ${FAILED}"
echo ""
echo "All repositories have been downloaded to: $(pwd)"
