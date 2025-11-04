#!/usr/bin/env bash
# Script to download all Bitwarden repositories from GitHub
# Usage: ./download-bitwarden-repos.sh [target_directory]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get target directory from argument or use current directory
TARGET_DIR="${1:-.}"
OWNER="bitwarden"

echo -e "${GREEN}Bitwarden Repository Downloader${NC}"
echo "======================================"
echo "This script will clone all public repositories from the ${OWNER} GitHub organization."
echo "Target directory: ${TARGET_DIR}"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Warning: GitHub CLI is not authenticated.${NC}"
    echo "You may encounter rate limiting issues."
    echo "Run 'gh auth login' to authenticate."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}"

echo "Fetching list of repositories..."

# Fetch all repositories from the organization
# We'll use gh api to get all repos (paginated)
REPOS=$(gh api "orgs/${OWNER}/repos" --paginate --jq '.[].clone_url')

if [ -z "$REPOS" ]; then
    echo -e "${RED}Error: No repositories found or failed to fetch repository list.${NC}"
    exit 1
fi

# Count total repos
TOTAL=$(echo "$REPOS" | wc -l)
CURRENT=0
SKIPPED=0
CLONED=0
UPDATED=0
FAILED=0

echo "Found ${TOTAL} repositories."
echo ""

# Clone or update each repository
while IFS= read -r repo_url; do
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
