#!/bin/bash

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Récupérer les derniers commits non poussés
last_push=$(git rev-parse @{u})
new_commits=$(git log $last_push..HEAD --pretty=format:"%H;%cd;%s" --date=iso-local)

# Si le fichier JSON n'existe pas encore, créer une structure de base
if [ ! -f "$JSON_FILE" ]; then
  echo "[" > $JSON_FILE
else
  # Retirer la dernière virgule si le JSON existe pour append proprement
  sed -i '$ s/,$//' $JSON_FILE
fi

# Ajouter les nouveaux commits au fichier JSON
echo "$new_commits" | while IFS=";" read commit_hash commit_date commit_message; do
    # Ignorer les commits qui commencent par '#'
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Extraire le tag et le fichier/composant uniquement si le format respecte Tag(scope)
    if [[ $commit_message =~ ^([A-Za-z]+)\(([A-Za-z0-9._-]+)\)\:?\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"

        # Si ":" est présent dans la description, on réarrange
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

    # Ajouter au JSON
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$description\"}," >> $JSON_FILE
done

# Fermer la structure JSON proprement
echo "]" >> $JSON_FILE

# Maintenant utiliser le JSON pour mettre à jour le fichier CHANGELOG.md
echo "# Changelog" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE
echo "| Date et Heure      | Commit (ID long)    | **Tag**      | *Scope*       | Description         |" >> $CHANGELOG_FILE
echo "|-------------------|--------------------|--------------|---------------|---------------------|" >> $CHANGELOG_FILE

# Lire le JSON et mettre à jour le fichier changelog
jq -r '.[] | "| \(.date) | [\(.commit)]('$REPO_URL'/commit/\(.commit)) | \(.tag) | \(.scope) | \(.description) |"' $JSON_FILE >> $CHANGELOG_FILE

