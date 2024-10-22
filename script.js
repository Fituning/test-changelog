document.addEventListener('DOMContentLoaded', function() {
    fetch('changelog.json')
    .then(response => response.json())
    .then(data => {
        const changelogList = document.getElementById('changelog-list');

        // Grouper les commits par tag
        const groupedByTag = data.reduce((acc, commit) => {
            const tag = commit.tag || "No Tag";  // Gérer les commits sans tag
            if (!acc[tag]) acc[tag] = [];
            acc[tag].push(commit);
            return acc;
        }, {});

        // Parcourir les groupes par tag et créer un tableau pour chaque groupe
        for (let tag in groupedByTag) {
            // Créer un conteneur pour chaque section de tag
            const section = document.createElement('div');
            section.classList.add('mb-4');
            
            // Titre du tag
            const title = document.createElement('h3');
            title.textContent = `Tag: ${tag}`;
            section.appendChild(title);

            // Créer un tableau pour le changelog de chaque tag
            const table = document.createElement('table');
            table.classList.add('table', 'table-striped');

            // Créer l'en-tête du tableau
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

            // Créer le corps du tableau
            const tbody = document.createElement('tbody');

            // Parcourir les commits par tag du plus récent au plus ancien
            groupedByTag[tag].reverse().forEach(commit => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${commit.date}</td>
                    <td><a href="${REPO_URL}/commit/${commit.commit}">${commit.commit}</a></td>
                    <td>${commit.scope || 'N/A'}</td>
                    <td>${commit.description || 'No Description'}</td>
                `;
                tbody.appendChild(row);
            });

            table.appendChild(tbody);
            section.appendChild(table);
            changelogList.appendChild(section);
        }
    })
    .catch(error => console.error('Erreur lors du chargement du fichier JSON :', error));
});
