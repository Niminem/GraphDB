import std/[json, tables, sets, os]
import ../src/[graph_db, query_lang]
import csv_parser







# when isMainModule:
#     var graph = newLabeledPropertyGraph()
#     graph.csvToNodes(currentSourcePath.parentDir / "internal_all.csv", true)
#     graph.csvToLinks(currentSourcePath.parentDir / "all_inlinks.csv", true)
#     graph.csvToNodeProperty(currentSourcePath.parentDir / "custom_extraction_all.csv", true)