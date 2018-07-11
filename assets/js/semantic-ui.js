jQuery('.ui.dropdown').dropdown()
jQuery('.ui.accordion').accordion()
jQuery('.ui.search')
    .search({
        searchOnFocus: true,
        minCharacters: 1,
        debug: true,
        verbose: true,
        source: false,
        apiSettings: {
            url: '/api/v1/search/user?query={query}',
        }})

