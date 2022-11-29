import std/[sugar, json, tables, sets]
import graph_db


# INITIAL TEST (adding nodes, links, simple query search)
# var graph = newLabeledPropertyGraph()

# let
#     homePage = graph.createNode(labels=["Homepage"], properties= %*{"url": "https://site.com/", "title":"Home Title"})
#     aboutPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/about", "title":"About Title"})
#     contactPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/contact", "title":"Contact Title"})

# let
#     internalLink1 = graph.createLink(lType="InternalOutbound", incoming=homePage, outgoing=aboutPage)
#     internallink2 = graph.createLink(lType="InternalOutbound", incoming=homePage, outgoing=contactPage)
#     internalLink3 = graph.createLink(lType="InternalOutbound", incoming=aboutPage, outgoing=contactPage)

# echo "Querying for urls that have INTERNAL_LINKS from HOMEPAGE (#1)"
# let match = collect(newseq):
#     for linkIdx in graph.types["InternalOutbound"]:
#         if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
# echo "match found: " & $match
# echo "Deleting homepage node"
# graph.deleteNode(homePage)
# let match2 = collect(newseq):
#     for linkIdx in graph.types["InternalOutbound"]:
#         if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
# echo "Querying for urls that have INTERNAL_LINKS from HOMEPAGE (#2)"
# echo "match found: " & $match2


# DELETING LINKS TEST
# var graph = newLabeledPropertyGraph()

# let
#     homePage = graph.createNode(labels=["Homepage"], properties= %*{"url": "https://site.com/", "title":"Home Title"})
#     aboutPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/about", "title":"About Title"})

# let internalLink1 = graph.createLink(lType="InternalOutbound", incoming=homePage, outgoing=aboutPage)

# echo "Labels: " & $graph.types
# echo "Node 1: " & $graph.nodes[homePage] & " ID: " & homePage
# echo "Node 2: " & $graph.nodes[aboutPage] & " ID: " & aboutPage
# echo "Link: " & $graph.links[internalLink1] & " ID: " & internalLink1
# echo "------"
# graph.deleteLink(internalLink1)
# echo "Labels: " & $graph.types
# echo "Node 1: " & $graph.nodes[homePage] & " ID: " & homePage
# echo "Node 2: " & $graph.nodes[aboutPage] & " ID: " & aboutPage
# assert graph.links.hasKey(internalLink1) == false