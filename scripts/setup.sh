#!/bin/bash
set -e

# Set working directory
rootDir="$(cd "$(dirname "$0")" && pwd)"
cd "${rootDir}/.."

# Define Ansible options
ansibleOptions=""

while getopts 't:e:' flag; do
  case "${flag}" in
  t) # tag
    ansibleOptions="${ansibleOptions} --tags ${OPTARG}"
    ;;
  e) # exclude tag
    ansibleOptions="${ansibleOptions} --skip-tags ${OPTARG}"
    ;;
  *)
    echo "Unexpected option ${flag}"
    exit 1
    ;;
  esac
done

# Exit on error function
exitOnError() {
  exitCode=$1
  errorMessage=$2
  [[ $exitCode -gt 0 ]] && (echo "Error: ${errorMessage}" && exit 1) || :
}

# Check if a command exists
isInstalled() {
  command -v "$1" >/dev/null 2>&1
}

# Determine OS type
OS_TYPE=$(uname -s)

echo "Running Setup for OS: ${OS_TYPE}"

# Install Ansible if not installed
if ! isInstalled ansible; then
  echo "Ansible not found. Installing..."

  case "$OS_TYPE" in
  Darwin)
    if ! isInstalled brew; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      exitOnError $? "Installing Homebrew"
    fi
    brew install ansible
    exitOnError $? "Installing Ansible with Homebrew"
    ;;
  Linux)
    if isInstalled apt; then
      sudo apt update && sudo apt install -y software-properties-common ansible git
      exitOnError $? "Installing Ansible with APT"
    else
      echo "Unsupported Linux distribution. Please install Ansible manually."
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: ${OS_TYPE}"
    exit 1
    ;;
  esac
fi

# Ensure ~/git directory exists
GIT_DIR="$HOME/git"
if [ ! -d "$GIT_DIR" ]; then
  echo "Creating directory: $GIT_DIR"
  mkdir -p "$GIT_DIR"
fi

# Clone the repository if it doesn’t exist
REPO_URL="https://${GITHUB_PAT}@github.com/seemywingz/provisions.git"
REPO_NAME="provisions"
if [ ! -d "$GIT_DIR/$REPO_NAME" ]; then
  echo "Cloning repository: $REPO_URL into $GIT_DIR"
  git clone "$REPO_URL" "$GIT_DIR/$REPO_NAME"
  exitOnError $? "Cloning Git repository"
else
  echo "Pulling latest changes..."
  cd "$GIT_DIR/$REPO_NAME" && git pull
  exitOnError $? "Updating Git repository"
fi

# Run Ansible Playbook
cd "$GIT_DIR/$REPO_NAME"
ansiblePlaybook="playbooks/local.yml"
echo "Running Setup: ansible-playbook ${ansibleOptions} ${ansiblePlaybook}"
ansible-playbook ${ansibleOptions} ${ansiblePlaybook}
exitOnError $? "Running Ansible Playbook"

cd -
