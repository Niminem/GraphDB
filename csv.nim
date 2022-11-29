import parsecsv
import graph_db


proc csvToNodes*(graph: var LabeledPropertyGraph | RDFTripleStoreGraph; file: string; labelIdx: int = -1) = 

    var p: CsvParser
    p.open(file)
    p.readHeaderRow()
    while p.readRow(): # remember: every value is initially a string
        # graph.createNode(properties=p.)
        break
    p.close()



when isMainModule:
    var graph = newLabeledPropertyGraph()
    graph.csvToNodes("internal_all.csv")