#!/bin/bash

# Récupérer les SHA des commits avant et après le push
last_sha=$1
new_sha=$2

# Récupérer l'URL du dépôt Git
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/.git/}

# Fichier changelog et JSON
CHANGELOG_FILE="CHANGELOG.md"
JSON_FILE="changelog.json"

# Récupérer les commits entre les deux SHA
new_commits=$(git log $last_sha..$new_sha --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S")

# Si le fichier JSON n'existe pas encore, créer une structure de base
if [ ! -f "$JSON_FILE" ]; then
  echo "[" > $JSON_FILE
else
  # Supprimer la dernière fermeture du tableau pour ajouter les nouveaux commits
  sed -i '$ s/]/,/' $JSON_FILE
fi

# Ajouter les nouveaux commits au fichier JSON
echo "$new_commits" | while IFS=";" read commit_hash commit_date commit_message; do
    # Accumuler les lignes suivantes pour le corps du commit
    commit_body=""
    while read body_line; do
        # Si la ligne est vide, c'est la fin du commit
        if [ -z "$body_line" ]; then
            break
        fi
        # Ajouter la ligne à la description du commit
        commit_body="$commit_body\n$body_line"
    done <<< "$(git show -s --format=%b $commit_hash)"

    # Remplacer les guillemets doubles et simples dans les messages de commit et description
    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    commit_body=$(echo "$commit_body" | sed 's/"/\\"/g' | sed "s/'/\\'/g")

    # Extraire le tag et le fichier/composant uniquement si le format respecte Tag(scope)
    if [[ $commit_message =~ ^([A-Za-z]+)\(([A-Za-z0-9._-]+)\)\:?\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"

        # Si ":" est dans la description, on retire la partie avant les deux-points du titre
        if [[ $description == *:* ]]; then
            description=$(echo "$description" | cut -d':' -f2-)
        fi
    elif [[ $commit_message =~ ^Merge.* ]]; then
        # Si c'est un commit de merge
        tag="Merge"
        file_component=""
        description=$commit_message
    else
        # Si pas de format Tag(scope), utiliser toute la description comme elle est
        tag=""
        file_component=""
        description=$commit_message
    fi

    # Concaténer le corps du commit dans la description principale
    if [[ ! -z "$commit_body" ]]; then
        description="$description\n$commit_body"
    fi

    # Concaténer toutes les lignes du commit body dans une seule description, et supprimer les nouvelles lignes excessives
    description=$(echo "$description" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

    # Ajouter chaque commit au JSON avec la description sans le titre si tag et scope sont présents
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$description\"}," >> $JSON_FILE
done

# Supprimer la dernière virgule après le dernier commit
sed -i '$ s/,$//' $JSON_FILE

# Fermer le tableau JSON proprement
echo "]" >> $JSON_FILE

echo "Le fichier JSON a été mis à jour correctement."
