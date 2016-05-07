# nim-wox
**Moved to https://github.com/Wox-launcher/LanguageBinding/**

Nim helper library for creating Wox plugin

I'm newbie in Nim :smile:

Somebody help me please rewrite `filter` function from Python to Nim, function code:

```python
def filter(self, query, items, key=lambda x: x, min_score=0, max_results=0):
    """
    Search filter

    :param str query: query string
    :param iterable items: items to search
    :param function key: function to create a string for the search query,
                         default return the item
    :param int min_score: if a non-zero value ignores the results with score
                          less than this value
    :param int max_results: if non-zero, reduces the number of results to
                            specified value
    :return list: list of filtred items
    """

    query = query.lower().strip()

    results = []

    for item in items:
        score = 0
        value = key(item).strip()
        if value == '':
            continue
        if value.lower().startswith(query):
            score = 100.0 - (len(value) / len(query))
        elif query in value.lower():
            score = 80.0 - (len(value) / len(query))
        if score:
            results.append(((100.0 / score, value.lower(), score), (item, score)))

    results.sort(reverse=False)

    results = [t[1] for t in results]

    if max_results and len(results) > max_results:
        results = results[:max_results]

    if min_score:
        results = [r for r in results if r[1] > min_score]

    return [t[0] for t in results]
```
