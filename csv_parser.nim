## Not part of the library, I will need to have a macro (query lang DSL) and support
## the user's unique needs with allowing control for Node/Link insertions.

import std/[parsecsv, tables, sequtils, jsonutils, sets, strutils, sugar, json]
import graph_db, query_lang

proc csvToNodes*(graph: var LabeledPropertyGraph; file: string; hasHeaders: bool) = 
    var p: CsvParser
    p.open(file)
    if hasHeaders: p.readHeaderRow()
    while p.readRow(): # remember: every value is initially a string
        let properties = toJson(toTable[string,string](zip(p.headers, p.row)))
        graph.createNode(properties=properties)
    p.close()

proc csvToLinks*(graph: var LabeledPropertyGraph; file: string; hasHeaders: bool) = 
    var p: CsvParser
    p.open(file)
    if hasHeaders: p.readHeaderRow()
    const PropertiesToKeep = ["Type", "Status Code", "Follow", "Link Position"]
    while p.readRow():
        let
            src = p.rowEntry("Source")
            dst = p.rowEntry("Destination")
        if all([src, dst], (s: string) => "lightchiropractic.sg" in s) and p.rowEntry("Type") == "Hyperlink":
            let
                lType = "INTERNAL_LINK"
                incoming = graph.getNodeIdByPropertyVal(property="Address",value=src)
                outgoing = graph.getNodeIdByPropertyVal("Address",dst)
                properties = zip(p.headers, p.row).filter(proc(item: (string, string)): bool = item[0] in PropertiesToKeep)
            graph.createLink(lType, incoming, outgoing, toJson(toTable[string, string](properties)))
    p.close()



when isMainModule:
    import times

    var graph = newLabeledPropertyGraph()

    var start = getTime()
    graph.csvToNodes("internal_all.csv", true)
    graph.csvToLinks("all_inlinks.csv", true)
    var finish = getTime()

    echo "Elapsed time: " & $(start - finish) # 1.5 - 1.9 seconds avg