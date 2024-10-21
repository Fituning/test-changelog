#!/bin/bash

# Fichier changelog
CHANGELOG_FILE="CHANGELOG.md"

# En-tête du changelog
echo "# Changelog" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE

# Obtenir les commits
git log --pretty=format:"%h %s" --reverse | while read line; do
    commit_hash=$(echo $line | awk '{print $1}')
    commit_message=$(echo $line | cut -d' ' -f2-)

    # Classer les commits selon les tags
    if [[ $commit_message == Added* ]]; then
        echo "## Added" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    elif [[ $commit_message == Changed* ]]; then
        echo "## Changed" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    elif [[ $commit_message == Deprecated* ]]; then
        echo "## Deprecated" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    elif [[ $commit_message == Removed* ]]; then
        echo "## Removed" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    elif [[ $commit_message == Fixed* ]]; then
        echo "## Fixed" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    elif [[ $commit_message == Security* ]]; then
        echo "## Security" >> $CHANGELOG_FILE
        echo "- $commit_message ($commit_hash)" >> $CHANGELOG_FILE
    fi
done

