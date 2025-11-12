#!/usr/bin/env bash

set -euo pipefail

# Add php binaries to path (sail)
export PATH="vendor/bin:$PATH"

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command returns non 0 exit status
check_command() {
  local cmd=$1
  local msg=$2
  set +e
  if ! $cmd &> /dev/null 2>&1; then
    echo
    echo -e "${RED}✗ Error: $msg${NC}"
    echo
    exit 1
  fi
  set -e
}

# Check dependencies
check_command "composer" "Composer could not be found. Please install Composer with PHP version >=8."
check_command "docker compose" "Docker Compose could not be found. Please install Docker with Compose or Podman with Compose and Docker compat." 
if [ -f ".env.example.sail" ]; then
  check_command "find .env" "Couldn't find a .env file. Please create it with ${CYAN}cp .env.example.sail .env${NC}"
else
  check_command "find .env" "Couldn't find a .env file. Please create it with ${CYAN}cp .env.example .env${NC}"
fi

# Install dependencies and start container
composer install

sail up --detach --build

# Install node packages
if [ -e "package.json" ]; then
  while true; do
    set +e
    sail npm install
    exit_code="$?"
    set -e

    if [ $exit_code -eq 0 ]; then
      break
    elif [ $exit_code -eq 128 ]; then
      sail-root-run chown sail -R /home/sail/.ssh
      sail-root-run chmod 700 -R /home/sail/.ssh
      sail-run bash -c 'echo "yes" | ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""'

      echo
      echo -e "${YELLOW}This project needs access to install NPM packages that are located"
      echo -e "in private GitHub repositories. To make this possible navigate to:"
      echo -e "${CYAN}https://github.com/settings/keys${NC}"
      echo -e "${YELLOW}and add this SSH public key:${NC}"
      echo
      sail-run bash -c 'cat ~/.ssh/id_ed25519.pub'

      echo
      echo -e "${YELLOW}When you are done hit ENTER.${NC}"
      echo
      read
    else
      exit
    fi
  done
fi

# Generate APP_KEY
sail php artisan key:generate

# Migrate Database
sail php artisan migrate

echo
echo -e "${GREEN}✓ Setup done!${NC}"
echo
echo -e "If the application has a seeder you can seed the database with:"
echo -e "  ${CYAN}sail php artisan db:seed${NC}"
