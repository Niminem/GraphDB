import std/[macros, json]
import graph_db

# CREATE (:Person:Actor {name: 'Tom Hanks', born: 1956})
# CREATE ()-[:ACTED_IN {roles: ['Forrest'], performance: 5}]->()
# CREATE (:Person:Actor {name: 'Tom Hanks', born: 1956})-[:ACTED_IN {roles: ['Forrest']}]->(:Movie {title: 'Forrest Gump'})<-[:DIRECTED]-(:Person {name: 'Robert Zemeckis', born: 1951})


macro CREATE(labels: varargs[untyped], properties: JsonNode = newJNull()) =
    echo labels.repr
    echo "----"
    echo properties.repr

CREATE [Branded, TopNavigation] (
    url: "https://www.site.com/contact",
    title: "contact us")

