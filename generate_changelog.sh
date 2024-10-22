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
  echo "," >> "$JSON_FILE"
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

    # Accumuler les lignes suivantes pour le corps du commit
    commit_body=""
    while read body_line; do
        if [ -z "$body_line" ]; then
            break
        fi
        commit_body="$commit_body $body_line"
    done <<< "$(git show -s --format=%b $commit_hash)"

    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    commit_body=$(echo "$commit_body" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    
    full_description="$commit_message"
    if [[ ! -z "$commit_body" ]]; then
        full_description="$full_description $commit_body"
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
    counter=$((counter + 1))
    echo -n "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$full_description\"}" >> "$JSON_FILE"
    # Ajouter une virgule entre les commits, sauf pour le dernier
    if [ $counter -lt $commit_count ]; then
        echo "," >> "$JSON_FILE"
    else
        echo "" >> "$JSON_FILE"
    fi
done

# Ajouter la fermeture du tableau JSON
echo "]" >> "$JSON_FILE"

echo "Le fichier JSON a été mis à jour avec succès."

# Mise à jour du fichier CHANGELOG.md avec les nouveaux commits
# Créer un en-tête pour le fichier CHANGELOG.md s'il n'existe pas
if [ ! -f "$CHANGELOG_FILE" ]; then
  echo "# Changelog" > "$CHANGELOG_FILE"
  echo "" >> "$CHANGELOG_FILE"
  echo "| Date et Heure      | Commit (ID long)    | **Tag**      | *Scope*       | Description         |" >> "$CHANGELOG_FILE"
  echo "|-------------------|--------------------|--------------|---------------|---------------------|" >> "$CHANGELOG_FILE"
fi

# Boucler sur les nouveaux commits et les ajouter au fichier CHANGELOG.md
echo "$commits" | while IFS=";" read commit_hash commit_date commit_message; do
    commit_tag=$(echo "$commit_message" | grep -oP '^[A-Za-z]+')
    commit_scope=$(echo "$commit_message" | grep -oP '\([A-Za-z0-9._-]+\)' | tr -d '()')
    commit_description=$(echo "$commit_message" | sed -E 's/^[A-Za-z]+\([A-Za-z0-9._-]+\)\:?\ ?//' | sed 's/[[:space:]]\+/ /g')

    # Ajouter chaque ligne correctement dans le fichier CHANGELOG.md
    echo "| $commit_date | [$commit_hash]($REPO_URL/commit/$commit_hash) | **$commit_tag** | *$commit_scope* | $commit_description |" >> "$CHANGELOG_FILE"
done

echo "Le fichier CHANGELOG.md a été mis à jour avec les nouveaux commits."
