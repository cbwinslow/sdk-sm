# Download Bitwarden Repositories Scripts

Two scripts are available to download all public repositories from the Bitwarden GitHub organization.

## Scripts Available

1. **download-bitwarden-repos.sh** - Uses GitHub CLI (gh) for authentication and better API access
2. **download-bitwarden-repos-simple.sh** - Uses curl and doesn't require GitHub CLI

## Prerequisites

### For download-bitwarden-repos.sh
- **Git**: Required for cloning repositories
- **GitHub CLI (gh)**: Required for fetching the repository list
  - Install from: https://cli.github.com/
  - Authenticate with: `gh auth login` (recommended but optional)

### For download-bitwarden-repos-simple.sh
- **Git**: Required for cloning repositories
- **curl**: Usually pre-installed on most systems
- **jq**: Required for parsing JSON
  - Install from: https://stedolan.github.io/jq/

## Usage

### Basic Usage (GitHub CLI version)

Download all repositories to the current directory:

```bash
./scripts/download-bitwarden-repos.sh
```

### Basic Usage (Simple version)

Download all repositories to the current directory:

```bash
./scripts/download-bitwarden-repos-simple.sh
```

### Download to a Specific Directory

Download all repositories to a specific target directory:

```bash
./scripts/download-bitwarden-repos.sh /path/to/target/directory
# or
./scripts/download-bitwarden-repos-simple.sh /path/to/target/directory
```

## What the Scripts Do

Both scripts perform the same operations:

1. Check for required dependencies
2. Fetch the complete list of public repositories from the Bitwarden organization
3. For each repository:
   - **If not present**: Clones the repository
   - **If already present**: Updates it with `git pull --ff-only`
4. Provide a summary of the operation

The main difference is the method used to fetch the repository list from GitHub.

## Features

- **Color-coded output** for better readability
- **Progress tracking** showing current repository number out of total
- **Handles existing repositories** by updating them instead of re-cloning
- **Error handling** with summary of successful and failed operations
- **Paginated API calls** to handle large numbers of repositories

## Output

The script provides:
- Real-time progress for each repository
- Final summary showing:
  - Total repositories processed
  - Number of newly cloned repositories
  - Number of updated repositories
  - Number of failed operations

## Example

```bash
$ ./scripts/download-bitwarden-repos-simple.sh ./bitwarden-repos
Bitwarden Repository Downloader (Simple Version)
======================================
This script will clone all public repositories from the bitwarden GitHub organization.
Target directory: ./bitwarden-repos

Fetching list of repositories...
  Fetching page 1...
Found 59 repositories.

[1/59] Processing server...
  Cloning...
  ✓ Cloned

[2/59] Processing clients...
  Cloning...
  ✓ Cloned

...

======================================
Download Complete!
======================================
Total repositories: 59
Newly cloned:       59
Updated:            0
Failed:             0

All repositories have been downloaded to: /path/to/bitwarden-repos
```

## Notes

- The script will create the target directory if it doesn't exist
- Repositories are cloned using HTTPS (no SSH key required)
- Authentication with GitHub CLI is recommended to avoid rate limiting
- The script only downloads public repositories from the Bitwarden organization
- Failed operations don't stop the script; it continues with remaining repositories

## Troubleshooting

### "GitHub CLI (gh) is not installed" (download-bitwarden-repos.sh)

Install the GitHub CLI from https://cli.github.com/ or use the simple version instead.

### "jq is not installed" (download-bitwarden-repos-simple.sh)

Install jq from https://stedolan.github.io/jq/ or use the GitHub CLI version instead.

### "GitHub CLI is not authenticated" (download-bitwarden-repos.sh)

Run `gh auth login` to authenticate. While optional, this is recommended to avoid rate limiting.

### Rate Limiting

If you encounter rate limiting without authentication:
1. Authenticate with: `gh auth login`
2. Or wait for the rate limit to reset (usually 1 hour)
