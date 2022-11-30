import std/[json, tables, sets, os, parsecsv, sugar, strutils]
import ../src/[graph_db, query_lang]
import modeling

# will just do the work rather than focusing on builiding reusable procs
#
#
#

proc findLinkOpportunities*(graph: var LabeledPropertyGraph; targetUrl: string; phrases: seq[string]): seq[string] =
    # 1. find all links that link to targetURl
    let targetNodeId = graph.getNodeIdByPropertyVal("Address", targetUrl)
    var existingLinksByNodeId = graph.nodes[targetNodeId].outgoing
    # 2. find phrases in tokens, if there's any match add the Node URL (Address property) to the result
    for id, node in graph.nodes.pairs:
        if id in existingLinksByNodeId: continue
        if node.properties.hasKey("Tokens"):
            let tokens = node.properties["Tokens"].to(seq[string]).join(" ")
            for phrase in phrases:
                if " " & phrase.toLower & " " in tokens:
                    result.add(node.properties["Address"].getStr)
                    break

proc findLinkOpportunities*(graph: var LabeledPropertyGraph; targetUrl: string): seq[string] =
    # 1. find all links that link to targetURl
    let targetNodeId = graph.getNodeIdByPropertyVal("Address", targetUrl)
    var existingLinksByNodeId = graph.nodes[targetNodeId].outgoing
    # 2. if there's any match add the Node URL (Address property) to the result *** This is the proc without phrases to search ***
    for id, node in graph.nodes.pairs:
        if id in existingLinksByNodeId: continue
        if node.properties.hasKey("Tokens"):
            result.add(node.properties["Address"].getStr)

when isMainModule:
    var graph = newLabeledPropertyGraph()
    graph.buildModel()
    echo graph.findLinkOpportunities("https://www.lightchiropractic.sg/breasts-affecting-health/")#, @["test"])