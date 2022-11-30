#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

trap "echo 'Missing parameter'; exit 1" INT TERM EXIT
username="$1"
password="$2"
company="$3"
reponame="$4"
branch="$5"
#remote="$4"
trap - INT TERM EXIT


CURL_OPTS=(-u "$username:$password" --silent)


echo "Validating BitBucket credentials..."
curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" > /dev/null || (
    echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
    exit 1
)

reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if BitBucket repository \"$company/$reponame\" exists..."
curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$company/$reponame" | grep "error" > /dev/null && (
    echo "BitBucket repository \"$company/$reponame\" does NOT exist, creating it..."
    curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$company/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' > /dev/null
)

echo "Setup Git"
git config --global --add safe.directory "/github/workspace"
git config --global user.email "githubactions@101digital.io"
git config --global user.name "Github Actions"

echo "Set the remote Repo.. https://"$username:$password"@bitbucket.org/$company/$reponame"
git remote add bitbucket https://"$username:$password"@bitbucket.org/$company/$reponame
git fetch bitbucket
echo "Pushing to remote..."
git push bitbucket $branch --porcelain --force-with-lease --force-if-includes
