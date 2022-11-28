import std/[sugar, json, tables, sets]
import graph_db

var graph = newLabeledPropertyGraph()

let
    homePage = graph.createNode(labels=["Homepage"], properties= %*{"url": "https://site.com/", "title":"Home Title"})
    aboutPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/about", "title":"About Title"})
    contactPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/contact", "title":"Contact Title"})

let
    internalLink1 = graph.createLink(label="InternalOutbound", incoming=homePage, outgoing=aboutPage)
    internallink2 = graph.createLink(label="InternalOutbound", incoming=homePage, outgoing=contactPage)
    internalLink3 = graph.createLink(label="InternalOutbound", incoming=aboutPage, outgoing=contactPage)

echo "Querying for urls that have INTERNAL_LINKS from HOMEPAGE (#1)"
let match = collect(newseq):
    for linkIdx in graph.labels["InternalOutbound"]:
        if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
echo "match found: " & $match
echo "Deleting homepage node"
graph.deleteNode(homePage)
let match2 = collect(newseq):
    for linkIdx in graph.labels["InternalOutbound"]:
        if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
echo "Querying for urls that have INTERNAL_LINKS from HOMEPAGE (#2)"
echo "match found: " & $match2