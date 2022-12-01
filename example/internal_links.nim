import std/[json, tables, sets, os, parsecsv, sugar, strutils, times, sequtils]
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
        if id in existingLinksByNodeId or id == targetNodeId: continue # should not link back to itself
        if node.properties.hasKey("Tokens"):
            let tokens = node.properties["Tokens"].to(seq[string]).join(" ")
            for phrase in phrases:
                if " " & phrase.toLower & " " in tokens:
                    result.add(node.properties["Address"].getStr)
                    break

# *** This is the proc without phrases to search ***
proc findLinkOpportunities*(graph: var LabeledPropertyGraph; targetUrl: string): seq[string] =
    # 1. find all links that link to targetURl
    let targetNodeId = graph.getNodeIdByPropertyVal("Address", targetUrl)
    var existingLinksByNodeId = graph.nodes[targetNodeId].outgoing
    # 2. if there's any match add the Node URL (Address property) to the result
    for id, node in graph.nodes.pairs:
        if id in existingLinksByNodeId or id == targetNodeId: continue # should not link back to itself
        # elif "/blog/" notin node.properties["Address"].getStr: continue # **** TEMPORARY **** (we're looking for blog article opportunities)
        elif node.properties.hasKey("Tokens"):
            result.add(node.properties["Address"].getStr)
        else: discard



when isMainModule:
    var graph = newLabeledPropertyGraph()
    var graphStart = getTime()
    graph.buildModel()
    echo "graph build exe time: " & $(getTime() - graphStart)

    # code here :)
    let urls1 = graph.findLinkOpportunities("https://getgoally.com/blog/5-tips-for-helping-a-child-with-adhd-clean-their-room/", @["room"])
    # let urls2 = graph.findLinkOpportunities("https://getgoally.com/blog/how-to-create-routines-for-a-child-with-autism/", @["routine"])
    var f = open("output.txt", fmWrite)
    for line in urls1:#.concat(urls2).deduplicate:
        if "/blog/" in line:
            f.writeLine(line)
    f.close()


    # ----------------------------- TEST --------------------------------------------------------------------------
    # var start = getTime()
    # echo graph.findLinkOpportunities("https://getgoally.com/blog/5-tips-for-going-to-the-dentist-with-autism/", @["dentist"])
    # echo "finding opps, elapsed time: " & $(getTime() - start)
    # adding to graph, time elapse: 24 seconds, 191 milliseconds, 191 microseconds, and 600 nanoseconds
    # @["https://getgoally.com/blog/tooth-brushing-struggles-with-autism/", "https://getgoally.com/blog/page/15/", "https://getgoally.com/blog/category/autism/page/6/"]
    # finding opps, elapsed time: 295 milliseconds, 830 microseconds, and 800 nanoseconds
