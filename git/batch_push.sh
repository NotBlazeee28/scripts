#!/bin/bash

# Term Color formatting using tput
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
NC=$(tput sgr0)

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "${RED}Error: Invalid number of arguments.${NC}"
    echo "${YELLOW}Usage: $0 <remote_name> <remote_url> <branch> <batch_size>${NC}"
    exit 1
fi

# Assign command-line arguments to variables
REMOTE_NAME=$1
REMOTE_URL=$2
BRANCH=$3
BATCH_SIZE=$4

# Validate that the current directory is a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "${RED}Error: Current directory '$(pwd)' is not a Git repository.${NC}"
    exit 1
fi
echo "${WHITE}Current repository directory: $(pwd)${NC}"

# Add or update the remote URL
echo "${CYAN}Configuring remote repository...${NC}"
if git remote | grep -q "^$REMOTE_NAME$"; then
    echo "${YELLOW}Remote '$REMOTE_NAME' already exists. Updating its URL to '$REMOTE_URL'...${NC}"
    if ! git remote set-url "$REMOTE_NAME" "$REMOTE_URL"; then
        echo "${RED}Error: Failed to update remote URL.${NC}"
        exit 1
    fi
else
    echo "${GREEN}Adding remote '$REMOTE_NAME' with URL '$REMOTE_URL'...${NC}"
    if ! git remote add "$REMOTE_NAME" "$REMOTE_URL"; then
        echo "${RED}Error: Failed to add remote.${NC}"
        exit 1
    fi
fi

# Fetch the latest changes from the remote repository
echo "${CYAN}Fetching latest changes from remote '$REMOTE_NAME'...${NC}"
if ! git fetch "$REMOTE_NAME"; then
    echo "${RED}Error: Failed to fetch from remote '$REMOTE_NAME'.${NC}"
    exit 1
fi

# Determine the range of commits to push
if git show-ref --quiet --verify "refs/remotes/$REMOTE_NAME/$BRANCH"; then
    range="$REMOTE_NAME/$BRANCH..HEAD"
    echo "${WHITE}Remote branch '$BRANCH' found. Range set to: $range${NC}"
else
    range="HEAD"
    echo "${YELLOW}Remote branch '$BRANCH' not found. Range set to: HEAD${NC}"
fi

# Count the number of commits in the range
n=$(git log --first-parent --format=format:x "$range" | wc -l)
echo "${CYAN}Total commits to push: $n${NC}"

if [ "$n" -eq 0 ]; then
    echo "${GREEN}${BOLD}No new commits to push. Remote is already up to date!${NC}"
else
    # Loop through the commits in batches and push them
    echo "${CYAN}Starting batch push (batch size: $BATCH_SIZE)...${NC}"
    for i in $(seq $((n - BATCH_SIZE)) -"$BATCH_SIZE" 1); do
        h=$(git log --first-parent --reverse --format=format:%H --skip "$i" -n1)
        if [ -n "$h" ]; then
            echo "${CYAN}Pushing commit $h (skip $i)...${NC}"
            if ! git push "$REMOTE_NAME" "$h:refs/heads/$BRANCH"; then
                echo "${RED}Error: Failed to push batch commit $h.${NC}"
                exit 1
            fi
        fi
    done
fi

# Push the HEAD to the specified branch on the remote
echo "${CYAN}Performing final push of HEAD to '$BRANCH'...${NC}"
if ! git push "$REMOTE_NAME" "HEAD:$BRANCH"; then
    echo "${RED}Error: Final push of HEAD to '$BRANCH' failed.${NC}"
    exit 1
fi

echo "${GREEN}${BOLD}Batch push completed successfully!${NC}"
