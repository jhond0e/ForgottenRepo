#!/bin/bash

API_KEY="LEAKIX-API-KEY"
BASE_URL="https://leakix.net/search?scope=leak&q=%2B%22https%3A%2F%2Fgithub.com%2F"
TMP_FILE="tmp.json"
REPO_FILE="repos.txt"
SAVE_TO_FILE=0

usage() {
  echo "Usage: $0 -u <user> [-o <output_file>]"
  echo "Options:"
  echo "  -u <user>           Specify the GitHub user to search for."
  echo "  -o <output_file>    (Optional) Save the results to a file instead of displaying them."
  exit 1
}

while getopts "u:o:h" opt; do
  case ${opt} in
    u )
      USER="$OPTARG"
      ;;
    o )
      RESULT_FILE="$OPTARG"
      SAVE_TO_FILE=1
      ;;
    h )
      usage
      ;;
    \? )
      usage
      ;;
  esac
done

if [ -z "$USER" ]; then
  usage
fi

> $REPO_FILE

check_repo() {
  REPO_URL=$1
  GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$REPO_URL" &> /dev/null
  if [ $? -eq 0 ]; then
    RESULT="[PUBLIC] $REPO_URL"
  else
    RESULT="[PRIVATE/NOT ACCESSIBLE] $REPO_URL"
    # Search for leaked .git/config URLs on Leakix
    LEAK_SEARCH_URL="https://leakix.net/search?page=0&q=%2Bplugin%3A%22GitConfigHttpPlugin%22+%2B%22${REPO_URL}%22&scope=leak"
    LEAK_URLS=$(curl -s -H "api-key: $API_KEY" -H "accept: application/json" "$LEAK_SEARCH_URL" | jq -r '.[] | .http.header.location' | sort -u | grep -v "null" | head -n1 | sed 's/$/\.git\/config/')
    if [ -n "$LEAK_URLS" ]; then
      RESULT="$RESULT found at:"
      for LEAK_URL in $LEAK_URLS; do
        RESULT="$RESULT $LEAK_URL"
      done
    fi
  fi

  if [ $SAVE_TO_FILE -eq 1 ]; then
    echo "$RESULT" >> $RESULT_FILE
  else
    echo "$RESULT"
  fi
}

for PAGE in {0..50}; do
  curl -s -H "api-key: $API_KEY" -H "accept: application/json" "${BASE_URL}${USER}%2F%22+%2Bplugin%3A%22GitConfigHttpPlugin%22&page=$PAGE" > $TMP_FILE

  if [ ! -s $TMP_FILE ]; then
    break
  fi

  grep -E -o "https:\/\/github\.com\/${USER}\/[^\s]+\.git" $TMP_FILE | sort -u >> $REPO_FILE

  sleep 1
done

sort -u $REPO_FILE -o $REPO_FILE

while read REPO_URL; do
  check_repo $REPO_URL
done < $REPO_FILE

rm -f $TMP_FILE $REPO_FILE
