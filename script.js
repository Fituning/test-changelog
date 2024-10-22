// Charger le fichier JSON et afficher les données dans le tableau
document.addEventListener('DOMContentLoaded', function() {
    fetch('changelog.json')
    .then(response => {
        if (!response.ok) {
            throw new Error("Erreur lors du chargement du changelog.json");
        }
        return response.json();
    })
    .then(data => {
        const changelogBody = document.getElementById('changelog-body');
        
        // Trier les commits du plus récent au plus ancien
        data.reverse().forEach(commit => {
            const row = document.createElement('tr');
            
            // Création des colonnes
            const dateCell = document.createElement('td');
            dateCell.textContent = commit.date;
            row.appendChild(dateCell);
            
            const commitCell = document.createElement('td');
            const commitLink = document.createElement('a');
            commitLink.href = `${commit.url}`; // URL du commit (URL à construire avec la base du repo)
            commitLink.textContent = commit.commit;
            commitCell.appendChild(commitLink);
            row.appendChild(commitCell);
            
            const tagCell = document.createElement('td');
            tagCell.textContent = commit.tag;
            row.appendChild(tagCell);
            
            const scopeCell = document.createElement('td');
            scopeCell.textContent = commit.scope;
            row.appendChild(scopeCell);
            
            const descriptionCell = document.createElement('td');
            descriptionCell.textContent = commit.description;
            row.appendChild(descriptionCell);
            
            // Ajouter la ligne au tableau
            changelogBody.appendChild(row);
        });
    })
    .catch(error => {
        console.error("Erreur lors de l'affichage du changelog: ", error);
    });
});
