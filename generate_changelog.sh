#!/bin/bash

# Fichier changelog
CHANGELOG_FILE="CHANGELOG.md"

# En-tête du changelog
echo "# Changelog" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE

# Obtenir les commits et vérifier qu'il y en a
git log --pretty=format:"%h;%cd;%s" --date=short --reverse | while IFS=";" read commit_hash commit_date commit_message; do
    # Ignorer les commits qui commencent par '#'
    if [[ $commit_message == \#* ]]; then
        continue
    fi

    # Extraire le tag et le fichier/composant du message
    tag=$(echo $commit_message | cut -d'(' -f1)
    file_component=$(echo $commit_message | cut -d'(' -f2 | cut -d')' -f1)
    description=$(echo $commit_message | cut -d')' -f2-)

    # Classer les commits selon les tags et ajouter au changelog
    case $tag in
        Added)
            echo "## Added" >> $CHANGELOG_FILE
            ;;
        Changed)
            echo "## Changed" >> $CHANGELOG_FILE
            ;;
        Deprecated)
            echo "## Deprecated" >> $CHANGELOG_FILE
            ;;
        Removed)
            echo "## Removed" >> $CHANGELOG_FILE
            ;;
        Fixed)
            echo "## Fixed" >> $CHANGELOG_FILE
            ;;
        Security)
            echo "## Security" >> $CHANGELOG_FILE
            ;;
    esac

    # Ajouter le commit avec ses informations
    echo "| $commit_date | $commit_hash | $file_component | $description |" >> $CHANGELOG_FILE
done

# Ajouter un en-tête pour les colonnes
sed -i '3i| Date       | Commit    | Fichier/Composant | Description |' $CHANGELOG_FILE
sed -i '4i|------------|-----------|-------------------|-------------|' $CHANGELOG_FILE


# Générer un fichier JSON
JSON_FILE="changelog.json"
echo "[" > $JSON_FILE

git log --pretty=format:'{"commit": "%h", "date": "%cd", "message": "%s"},' --date=short --reverse | sed '$ s/,$//' >> $JSON_FILE

echo "]" >> $JSON_FILE


# Convertir le changelog en PDF
pandoc CHANGELOG.md -o CHANGELOG.pdf
