document.addEventListener('DOMContentLoaded', function() {
    const changelog = [
        "Version 1.0 - Initial release",
        "Version 1.1 - Minor bug fixes",
        "Version 1.2 - Performance improvements"
    ];

    const changelogList = document.getElementById('changelog-list');

    changelog.forEach(function(item) {
        const li = document.createElement('li');
        li.className = 'list-group-item';
        li.textContent = item;
        changelogList.appendChild(li);
    });
});
