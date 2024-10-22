#!/bin/bash

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Lire le JSON existant (si présent) et le copier temporairement
if [ -f "$JSON_FILE" ]; then
  jq '.' "$JSON_FILE" > temp.json
else
  echo "[" > temp.json
fi

# Obtenir les commits non poussés
commits=$(git log origin/main..HEAD --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S")

# Vérifier si des commits sont présents
if [ -z "$commits" ]; then
  echo "Aucun nouveau commit à traiter."
  exit 0
fi

# Supprimer la dernière ligne du fichier JSON temporaire pour éviter d'avoir la dernière virgule
sed -i '$ d' temp.json

# Ajouter un nouveau tableau JSON temporaire avec les nouveaux commits
echo "," >> temp.json  # Ajoute une virgule pour séparer l'ancien contenu des nouveaux commits

# Traiter chaque commit pour l'ajouter dans le fichier JSON
first_commit=true
echo "$commits" | while IFS=";" read commit_hash commit_date commit_message; do
    # Accumuler les lignes suivantes pour le corps du commit
    commit_body=""
    while read body_line; do
        if [ -z "$body_line" ]; then
            break
        fi
        commit_body="$commit_body\n$body_line"
    done <<< "$(git show -s --format=%b $commit_hash)"

    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    commit_body=$(echo "$commit_body" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    
    full_description="$commit_message"
    if [[ ! -z "$commit_body" ]]; then
        full_description="$full_description\n$commit_body"
    fi
    full_description=$(echo "$full_description" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

    if [[ $commit_message =~ ^([A-Za-z]+)\(([A-Za-z0-9._-]+)\)\:?\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"
        if [[ $description == *:* ]]; then
            description=$(echo "$description" | cut -d':' -f2-)
        fi
    elif [[ $commit_message =~ ^Merge.* ]]; then
        tag="Merge"
        file_component=""
        description=$commit_message
    else
        tag=""
        file_component=""
        description=$commit_message
    fi

    # Concaténer la description et ajouter le commit au fichier JSON
    if [ "$first_commit" = true ]; then
        echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$full_description\"}" >> temp.json
        first_commit=false
    else
        echo ",{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$full_description\"}" >> temp.json
    fi
done

# Ajouter la fermeture du tableau JSON
echo "]" >> temp.json

# Remplacer le fichier JSON d'origine par le fichier temporaire
mv temp.json "$JSON_FILE"

echo "Le fichier JSON a été mis à jour avec succès."
