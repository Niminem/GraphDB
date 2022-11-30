import std/[json, tables, sets, os]
import ../src/[graph_db, query_lang]
import parsing


# proc getNodeIdByPropertyVal*(graph: var LabeledPropertyGraph; property, value: string): string = 
# proc tokenizeHtmlBody*(htmlSrc: string): seq[string] =
proc addNodeProperty*(graph: var LabeledPropertyGraph; nodeId, property, value: string) =
    doAssert not graph.nodes[nodeId].properties.hasKey(property), "Node already has property: " & property
    graph.nodes[nodeId].properties.add(property, %*value)

# # nee
# for graph.nodes[]

when isMainModule:
    var graph = newLabeledPropertyGraph()
    graph.csvToNodes(currentSourcePath.parentDir / "csv_files" / "internal_all.csv", true)
    # graph.csvToLinks(currentSourcePath.parentDir  / "csv_files" / "all_inlinks.csv", true)
    graph.csvToNodeProperty(currentSourcePath.parentDir / "csv_files" / "custom_extraction_all.csv", true)
