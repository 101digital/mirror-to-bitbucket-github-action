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
ignorelist=($6)
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


#remote=$(echo $remote | tr '[:upper:]' '[:lower:]')
#
#echo "Checking for remote \"$remote\"..."
#git remote get-url "$remote" &> /dev/null || (
#    echo "Repository has no remote \"$remote\", creating it..."
#    git remote add "$remote" https://$username@bitbucket.org/$username/$reponame.git
#)


echo "Pushing to remote..."
echo "Cleaning the commit history.."
rm -rf .git
git init -b $branch
git config --global --add safe.directory "*"
git config --global user.email "githubactions@101digital.io"
git config --global user.name "Github Actions"

echo "Adding ignore items if defined"
if [ -n "$ignorelist" ]; then
for item in "${ignorelist[@]}" ; do echo $item >> .gitignore ; done
fi

echo "Commit the latest changes to $branch branch.."
git add .
git commit -m "Sync latest changes to UD"
echo "Set the remote Repo.. https://"$username:$password"@bitbucket.org/$company/$reponame"
git remote add bitbucket https://"$username:$password"@bitbucket.org/$company/$reponame
echo "Pushing to remote..."
git push bitbucket $branch --porcelain --force-with-lease --force-if-includes
