#!/bin/bash

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Récupérer les derniers commits non poussés sans fuseau horaire
last_push=$(git rev-parse @{u})
new_commits=$(git log $last_push..HEAD --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S")

# Si le fichier JSON n'existe pas encore, créer une structure de base
if [ ! -f "$JSON_FILE" ]; then
  echo "[" > $JSON_FILE
else
  # Retirer la dernière virgule si le JSON existe pour append proprement
  sed -i '$ s/,$//' $JSON_FILE
fi

# Compteur pour vérifier si des commits ont été ajoutés
commit_count=0

# Ajouter les nouveaux commits au fichier JSON
echo "$new_commits" | while IFS=";" read commit_hash commit_date commit_message; do
    # Ignorer les commits qui commencent par '#'
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Remplacer les guillemets doubles et simples dans les messages de commit
    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")

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
    if [ $commit_count -ne 0 ]; then
        echo "," >> $JSON_FILE  # Ajouter une virgule avant chaque commit sauf le premier
    fi

    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$description\"}" >> $JSON_FILE

    commit_count=$((commit_count + 1))
done

# Fermer la structure JSON proprement si des commits ont été ajoutés
if [ $commit_count -ne 0 ]; then
  echo "]" >> $JSON_FILE
else
  echo "[]" > $JSON_FILE
fi

echo "Les nouveaux commits non poussés ont été ajoutés au JSON."
