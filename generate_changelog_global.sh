#!/bin/bash

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Nettoyer le fichier JSON s'il existe déjà
if [ -f "$JSON_FILE" ]; then
  rm "$JSON_FILE"
fi

# Créer une structure de base pour le fichier JSON
echo "[" > $JSON_FILE

# Obtenir tous les commits du dépôt du plus ancien au plus récent sans fuseau horaire
git log --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S" --reverse | while IFS=";" read commit_hash commit_date commit_message; do
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

    # Ajouter chaque commit au JSON
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$description\"}," >> $JSON_FILE
done

# Retirer la dernière virgule et fermer la structure JSON proprement
sed -i '$ s/,$//' $JSON_FILE
echo "]" >> $JSON_FILE

echo "Le fichier JSON a été généré et nettoyé avec succès."
