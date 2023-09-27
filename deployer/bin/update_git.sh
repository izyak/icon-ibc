#!/bin/bash

# This script serves as a wrapper command for the deployment script available at: https://github.com/izyak/icon-ibc.

# Check if an argument was provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <branch_or_tag>"
  exit 1
fi
cd /opt/deployer/root/icon-ibc
git stash
git pull

branch_or_commit="$1"
# Perform the git checkout
git checkout "$branch_or_commit"
git pull


# Check the exit status of the git command
if [ $? -eq 0 ]; then
  echo "Checked out: $branch_or_commit"
else
  echo "Failed to checkout: $branch_or_commit"
  exit 1
fi

exit 0