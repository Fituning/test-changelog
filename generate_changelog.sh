#!/bin/bash

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Récupérer les SHA des commits avant et après le push
last_sha=$1
new_sha=$2

# Vérifier si les variables sont définies
if [ -z "$last_sha" ] || [ -z "$new_sha" ]; then
  echo "Les SHA des commits avant et après le push doivent être spécifiés."
  exit 1
fi

# Lire le JSON existant (si présent)
if [ ! -f "$JSON_FILE" ]; then
  echo "[" > "$JSON_FILE"
else
  # Supprimer la dernière ligne pour pouvoir ajouter de nouveaux commits proprement
  sed -i '$ d' "$JSON_FILE"
fi

# Obtenir les nouveaux commits entre les deux SHA du plus ancien au plus récent
commits=$(git log --reverse $last_sha..$new_sha --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S")
commit_count=$(echo "$commits" | wc -l) # Compter le nombre de commits pour gérer la virgule
counter=0 # Compteur pour savoir quand nous sommes au dernier commit

# Traiter chaque commit pour l'ajouter dans le fichier JSON
echo "$commits" | while IFS=";" read commit_hash commit_date commit_message; do
    # Ignorer les commits qui commencent par un "#"
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Accumuler les lignes suivantes pour le corps du commit (description)
    commit_body=""
    while read body_line; do
        if [ -z "$body_line" ]; then
            break
        fi
        commit_body="$commit_body $body_line"
    done <<< "$(git show -s --format=%b $commit_hash)"

    # Nettoyage des guillemets et des retours à la ligne dans les messages de commit et la description
    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    commit_body=$(echo "$commit_body" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    full_description="$commit_body"

    # Gestion du format "Tag Scope" et description
    if [[ $commit_message =~ ^([A-Za-z]+)\ ([A-Za-z0-9._-]+)\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"
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
    counter=$((counter + 1))
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$full_description\"}," >> "$JSON_FILE"

done

# Ajouter la fermeture du tableau JSON
echo "]" >> "$JSON_FILE"

echo "Le fichier JSON a été mis à jour avec succès."

# Régénérer entièrement le fichier CHANGELOG.md en triant les commits du plus récent au plus ancien
echo "# Changelog" > "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"
echo "| Date et Heure      | Commit (ID long)    | **Tag**      | *Scope*       | Description         |" >> "$CHANGELOG_FILE"
echo "|-------------------|--------------------|--------------|---------------|---------------------|" >> "$CHANGELOG_FILE"

# Lire le fichier JSON et ajouter les informations dans le changelog du plus récent au plus ancien
cat $JSON_FILE | grep -oP '{.*?}' | tac | while read -r line; do
    commit_hash=$(echo $line | grep -oP '"commit":\s*"\K[^"]+')
    commit_date=$(echo $line | grep -oP '"date":\s*"\K[^"]+')
    commit_tag=$(echo $line | grep -oP '"tag":\s*"\K[^"]+')
    commit_scope=$(echo $line | grep -oP '"scope":\s*"\K[^"]+')
    commit_description=$(echo $line | grep -oP '"description":\s*"\K[^"]+')

    # Ajouter chaque ligne correctement dans le fichier CHANGELOG.md
    echo "| $commit_date | [$commit_hash]($REPO_URL/commit/$commit_hash) | **$commit_tag** | *$commit_scope* | $commit_description |" >> "$CHANGELOG_FILE"
done

echo "Le fichier CHANGELOG.md a été mis à jour avec succès."
