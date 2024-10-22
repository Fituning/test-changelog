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

    # Concaténer le corps du commit dans la description principale
    full_description="$commit_message"
    if [[ ! -z "$commit_body" ]]; then
        full_description="$full_description\n$commit_body"
    fi

    # Concaténer toutes les lignes du commit body dans une seule description, et supprimer les nouvelles lignes excessives
    full_description=$(echo "$full_description" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

    # Extraire le tag et le fichier/composant uniquement si le format respecte Tag(scope)
    if [[ $commit_message =~ ^([A-Za-z]+)\(([A-Za-z0-9._-]+)\)\:?\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
    elif [[ $commit_message =~ ^Merge.* ]]; then
        # Si c'est un commit de merge
        tag="Merge"
        file_component=""
    else
        # Sinon, utiliser une description par défaut sans tag ni scope
        tag=""
        file_component=""
    fi

    # Ajouter chaque commit au JSON avec la description concaténée
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$full_description\"}," >> $JSON_FILE
done

# Retirer la dernière virgule et fermer la structure JSON proprement
sed -i '$ s/,$//' $JSON_FILE
echo "]" >> $JSON_FILE

echo "Le fichier JSON a été généré et nettoyé avec succès."
