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

# Prompt the user to enter the directory where they want to clone the repos
# If an argument is provided, use it instead
TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
    read -rp "${CYAN}Enter the directory where you want to clone the repositories : ${NC}~/" TARGET_DIR
fi

# Expand tilde (~) if present in the target directory path
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# If a relative path is entered, it will resolve relative to the HOME directory (e.g. 'folder' -> '~/folder')
if [[ "$TARGET_DIR" != /* ]]; then
    TARGET_DIR="$HOME/$TARGET_DIR"
fi

# Validate the directory
if [ -z "$TARGET_DIR" ]; then
    echo "${RED}Error: No directory specified.${NC}"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    read -rp "${YELLOW}Directory '$TARGET_DIR' does not exist. Do you want to create it? (y/N): ${NC}" CREATE_DIR
    if [[ "$CREATE_DIR" =~ ^[Yy]$ ]]; then
        mkdir -p "$TARGET_DIR"
    else
        echo "${RED}Error: Directory '$TARGET_DIR' does not exist. Exiting.${NC}"
        exit 1
    fi
fi

# Enter the target directory
cd "$TARGET_DIR" || exit 1
echo "${WHITE}Entered directory: $(pwd)${NC}"

# Step 1: Setup Tools

echo "${CYAN}Cloning or Updating extract-tools if exists...${NC}"
if [ -d "prebuilts/extract-tools" ]; then
    echo "${GREEN}extract-tools already exists, updating...${NC}"
    (cd prebuilts/extract-tools && git pull)
else
    mkdir -p prebuilts
    git clone https://github.com/LineageOS/android_prebuilts_extract-tools.git -b lineage-23.2 prebuilts/extract-tools
fi

echo "${CYAN}Cloning or Updating extract-utils if exists...${NC}"
if [ -d "tools/extract-utils" ]; then
    echo "${GREEN}extract-utils already exists, updating...${NC}"
    (cd tools/extract-utils && git pull)
else
    mkdir -p tools
    git clone https://github.com/LineageOS/android_tools_extract-utils.git -b lineage-23.2 tools/extract-utils
fi

# Step 2: Clone JDK

echo "${CYAN}Cloning JDK 21...${NC}"
if [ -d "prebuilts/jdk/jdk21" ]; then
    echo "${GREEN}JDK 21 already exists, skipping clone...${NC}"
else
    mkdir -p prebuilts/jdk
    git clone --depth=1 --branch android16-qpr2-release https://android.googlesource.com/platform/prebuilts/jdk/jdk21 prebuilts/jdk/jdk21
fi

echo "${GREEN}${BOLD}Setup tools completed successfully!${NC}"
