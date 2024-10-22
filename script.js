document.addEventListener('DOMContentLoaded', function() {
    // Charger les données du fichier changelog.json
    fetch('changelog.json')
        .then(response => response.json())
        .then(data => {
            const groupedCommits = groupByTag(data);
            const changelogList = document.getElementById('changelog-list');

            // Parcourir les groupes de commits et générer les tableaux
            Object.keys(groupedCommits).forEach(tag => {
                const sortedCommits = sortCommitsByDate(groupedCommits[tag]);

                // Ajouter un titre pour chaque groupe (tag)
                const tagHeader = document.createElement('h3');
                tagHeader.className = 'mt-3';
                tagHeader.textContent = `Tag: ${tag}`;
                changelogList.appendChild(tagHeader);

                // Créer une table pour les commits
                const table = document.createElement('table');
                table.className = 'table table-striped';

                // Ajouter l'en-tête du tableau
                const thead = document.createElement('thead');
                thead.innerHTML = `
                    <tr>
                        <th>Date et Heure</th>
                        <th>Commit (ID long)</th>
                        <th>Scope</th>
                        <th>Description</th>
                    </tr>
                `;
                table.appendChild(thead);

                // Ajouter les commits dans le tableau
                const tbody = document.createElement('tbody');
                sortedCommits.forEach(commit => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${commit.date}</td>
                        <td><a href="${REPO_URL}/commit/${commit.commit}">${commit.commit}</a></td>
                        <td>${commit.scope}</td>
                        <td>${commit.description}</td>
                    `;
                    tbody.appendChild(row);
                });
                table.appendChild(tbody);
                changelogList.appendChild(table);
            });
        })
        .catch(error => console.error('Erreur lors du chargement du fichier JSON:', error));

    // Fonction pour regrouper les commits par tag
    function groupByTag(commits) {
        return commits.reduce((acc, commit) => {
            const tag = commit.tag || 'No Tag';
            if (!acc[tag]) {
                acc[tag] = [];
            }
            acc[tag].push(commit);
            return acc;
        }, {});
    }

    // Trier les commits par date (du plus récent au plus ancien)
    function sortCommitsByDate(commits) {
        return commits.sort((a, b) => new Date(b.date) - new Date(a.date));
    }
});
