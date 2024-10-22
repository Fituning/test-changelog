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

# Obtenir tous les commits poussés sur la branche principale du plus récent au plus ancien
git log main --pretty=format:"%H;%cd;%s" --date=format:"%Y-%m-%d %H:%M:%S" | tac | while IFS=";" read commit_hash commit_date commit_message; do
    # Vérifier si le commit message commence par un #
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Accumuler les lignes suivantes pour le corps du commit
    commit_body=""
    while read body_line; do
        # Si la ligne est vide, c'est la fin du commit
        if [ -z "$body_line" ];then
            break
        fi
        # Ajouter la ligne à la description du commit
        commit_body="$commit_body $body_line"
    done <<< "$(git show -s --format=%b $commit_hash)"

    # Remplacer les guillemets doubles et simples dans les messages de commit et description
    commit_message=$(echo "$commit_message" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    commit_body=$(echo "$commit_body" | sed 's/"/\\"/g' | sed "s/'/\\'/g")

    # Extraire le tag et le fichier/composant uniquement si le format respecte Tag(scope)
    if [[ $commit_message =~ ^([A-Za-z]+)\(([A-Za-z0-9._-]+)\)\:?\ ?(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        file_component="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"

        # Si ":" est dans la description, on retire la partie avant les deux-points
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
        description="$description $commit_body"
    fi

    # Supprimer les retours à la ligne dans la description
    description=$(echo "$description" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

    # Ajouter chaque commit au JSON avec la description modifiée
    echo "{\"commit\": \"$commit_hash\", \"date\": \"$commit_date\", \"tag\": \"$tag\", \"scope\": \"$file_component\", \"description\": \"$description\"}," >> $JSON_FILE
done

# Retirer la dernière virgule et fermer la structure JSON proprement
sed -i '$ s/,$//' $JSON_FILE
echo "]" >> $JSON_FILE

echo "Le fichier JSON a été généré et nettoyé avec succès."

# Créer un en-tête pour le fichier CHANGELOG.md
echo "# Changelog" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE
echo "| Date et Heure      | Commit (ID long)    | **Tag**      | *Scope*       | Description         |" >> $CHANGELOG_FILE
echo "|-------------------|--------------------|--------------|---------------|---------------------|" >> $CHANGELOG_FILE

# Lire le fichier JSON et ajouter les informations dans le changelog du plus ancien au plus récent
cat $JSON_FILE | grep -oP '{.*?}' | tac | while read -r line; do
    commit_hash=$(echo $line | grep -oP '"commit":\s*"\K[^"]+')
    commit_date=$(echo $line | grep -oP '"date":\s*"\K[^"]+')
    commit_tag=$(echo $line | grep -oP '"tag":\s*"\K[^"]+')
    commit_scope=$(echo $line | grep -oP '"scope":\s*"\K[^"]+')
    commit_description=$(echo $line | grep -oP '"description":\s*"\K[^"]+')

    # Ajouter chaque ligne correctement dans le fichier CHANGELOG.md
    echo "| $commit_date | [$commit_hash]($REPO_URL/commit/$commit_hash) | **$commit_tag** | *$commit_scope* | $commit_description |" >> $CHANGELOG_FILE
done

echo "Le fichier CHANGELOG.md a été mis à jour avec succès."
