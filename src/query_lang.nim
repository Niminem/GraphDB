import std/[macros, json, sets, tables]
import graph_db

proc getNodeIdByPropertyVal*(graph: var LabeledPropertyGraph; property, value: string): string = # quick and dirty query for csv_parser
    for key,val in graph.nodes.pairs:
        if val.properties[property].getStr == value: return key

# CREATE (:Person:Actor {name: 'Tom Hanks', born: 1956})
# CREATE ()-[:ACTED_IN {roles: ['Forrest'], performance: 5}]->()
# CREATE (:Person:Actor {name: 'Tom Hanks', born: 1956})-[:ACTED_IN {roles: ['Forrest']}]->(:Movie {title: 'Forrest Gump'})<-[:DIRECTED]-(:Person {name: 'Robert Zemeckis', born: 1951})


# macro CREATE(labels: varargs[untyped], properties: JsonNode = newJNull()) =
#     echo labels.repr
#     echo "----"
#     echo properties.repr

# CREATE [Branded, TopNavigation] (
#     url: "https://www.site.com/contact",
#     title: "contact us")

# Cyper is a pattern matching query language made for graphs
# - Declaritive ***
# - Expressive
# ex.
# (:Person {name: "Dan"})-[:Loves]->(:Person {name:"Anne")
# - Pattern Matching (focused on this)
# MATCH graph query patterns ex:
# MATCH (:Person {name: "Dan"})-[:Loves]->(whom) return whom # whom is variable
# MATCH (n) ex 2, returns all nodes in database
# RETURN n
# non-trivial ex:
