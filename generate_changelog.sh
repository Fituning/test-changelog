#!/bin/bash

# URL de ton dépôt GitHub (remplace par ton URL)
REPO_URL="https://github.com/Fituning/test-changelog"

# Fichier changelog
CHANGELOG_FILE="CHANGELOG.md"

# En-tête du changelog
echo "# Changelog" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE

# Ajouter les colonnes au changelog
echo "| Date et Heure      | Commit (ID long)    | **Tag**      | *Scope*       | Description         |" >> $CHANGELOG_FILE
echo "|-------------------|--------------------|--------------|---------------|---------------------|" >> $CHANGELOG_FILE

# Obtenir les commits du plus récent au plus ancien
git log --pretty=format:"%H;%cd;%s" --date=iso | while IFS=";" read commit_hash commit_date commit_message; do
    # Ignorer les commits qui commencent par '#'
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Extraire le tag et le fichier/composant uniquement si le format respecte Tag(scope)
    if [[ $commit_message =~ ^[A-Za-z]+\([A-Za-z0-9._-]+\)\: ]]; then
        tag=$(echo $commit_message | cut -d'(' -f1)
        file_component=$(echo $commit_message | cut -d'(' -f2 | cut -d')' -f1)
        description=$(echo $commit_message | cut -d')' -f2-)

        # Si ":" est présent dans la description, extraire la partie avant et après le ":"
        if [[ $description == *:* ]]; then
            before_colon=$(echo $description | cut -d':' -f1)
            after_colon=$(echo $description | cut -d':' -f2-)
            description="$after_colon ($before_colon)"
        fi
    else
        # Sinon, utiliser une description par défaut sans tag ni scope
        tag=""
        file_component=""
        description=$commit_message
    fi

    # Formater la ligne avec les colonnes requises
    commit_link="[$commit_hash]($REPO_URL/commit/$commit_hash)"
    echo "| $commit_date | $commit_link | **$tag** | *$file_component* | $description |" >> $CHANGELOG_FILE
done


# Générer un fichier JSON
JSON_FILE="changelog.json"
echo "[" > $JSON_FILE

git log --pretty=format:'{"commit": "%h", "date": "%cd", "message": "%s"},' --date=short --reverse | sed '$ s/,$//' >> $JSON_FILE

echo "]" >> $JSON_FILE
