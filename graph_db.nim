import oids, tables, sets, json, sugar

type
    NodeID* = string # alias for reasoning behind return values in specific procedures
    LinkID* = string # alias for reasoning behind return values in specific procedures
    Node* = object
        # think like "incoming from relationship X" or "outgoing from relationship Y"
        outgoing*, incoming*, labels*: HashSet[string]
        # A conventional requirement for graph databases is to locate all nodes and vertexes
        # having some particular attribute. This opens a Pandora’s box of indexing schemes.
        properties*: JsonNode
    Link* = object
    # "To perform a graph traversal, i.e. to walk from vertex to vertex,
    # following only connecting edges, one needs to know which edges come in
    # and which edges go out. Of course, these can be found in the edge table
    # but searching the edge table is absurd"
        label*: string
        head*, tail*: string
        properties*: JsonNode
    NodeTable* = Table[string, Node]
    LinkTable* = Table[string, Link]
    LabelTable* = Table[string, HashSet[string]]
    LabeledPropertyGraph* = object # best optimized for 'traversing known relationships'
        nodes*: NodeTable
        links*: LinkTable
        labels*: LabelTable
    RDFTripleStoreGraph* = object # learn it, add it. start here: https://www.youtube.com/watch?v=yOYodfN84N4&t=2965s
                                  # best optimized for 'inferring new relationships' ex: inference engines
    GraphType* = enum
        labeledProperty, rdfTripleStore

# GRAPHS
proc newLabeledPropertyGraph*(): LabeledPropertyGraph =
    result
    # TODO: robust graph creation w/ initial support for parsing & processing CSV files



# NODES
proc createNode*(graph: var LabeledPropertyGraph; labels: openArray[string] = @[];
                    properties: JsonNode = newJNull()): NodeID {.discardable.} =
    # generate unqiue Node ID
    let nodeId = $genOid()
    # add node to Node table with a unique ID (key)
    graph.nodes[nodeId] = Node(properties: properties, labels: labels.toHashSet)
    # add node lables to Label table
    for label in labels:
        if graph.labels.hasKeyOrPut(label, toHashSet([nodeId])):
            graph.labels[label].incl(nodeId)
    # return discardable Node ID for chaining/eval purposes
    return nodeId



proc deleteNode*(graph: var LabeledPropertyGraph; nodeId: string;) = # needs robust exception handling & return value at some point

    # removes all Links and labels to Links connecting to/from this node
    for linkId in (graph.nodes[nodeId].outgoing + graph.nodes[nodeId].incoming):
        graph.labels[graph.links[linkId].label].excl(linkId) # deletes reference of Link from Label table
        graph.links.del(linkId) # deletes all connected link IDs/keys from Link Table (no broken link rule)

    # deletes node ID from all labeled sets
    for label in graph.nodes[nodeId].labels:
        graph.labels[label].excl(nodeId)
    # delete node from Node table
    graph.nodes.del(nodeId)



# LINKS
proc createLink*(graph: var LabeledPropertyGraph; label, incoming, outgoing: string;
                properties: JsonNode = newJNull()): LinkID {.discardable.} =
    # generate unqiue Link ID
    let linkId: NodeID = $genOid()
    # add new Link to graph
    graph.links[linkId] = Link(label: label, head: incoming, tail: outgoing, properties: properties)
    # add Link label to Labels table (if not exist) & add Link ID to label's set in Label table
    if graph.labels.hasKeyOrPut(label, toHashSet([linkId])):
        graph.labels[label].incl(linkId)
    # add Link ID to incoming set in Node ID (incoming)
    graph.nodes[incoming].incoming.incl(linkId)
    # add Link ID to outgoing set in Node ID (outgoing)
    graph.nodes[outgoing].outgoing.incl(linkId)
    # return discardable Link ID for chaining/eval purposes
    return linkId

proc deleteLink*(graph: var LabeledPropertyGraph; linkId: string) = # needs robust exception handling & return value at some point
    # delete linkId from label in Label table
    graph.labels[graph.links[linkId].label].excl(linkId)
    # delete linkId from head property (incoming for node) nodeId in Node Table
    graph.nodes[graph.links[linkId].head].incoming.excl(linkId)
    # delete linkId from tail property (outgoing for node) nodeId in Node Table
    graph.nodes[graph.links[linkId].tail].outgoing.excl(linkId)
    # delete linkId from Link table
    graph.links.del(linkId)



# Rapid prototyping & testing (develop robust test suite)
when isMainModule:
    var graph = newLabeledPropertyGraph()

    let
        homePage = graph.createNode(labels=["Homepage"], properties= %*{"url": "https://site.com/", "title":"Home Title"})
        aboutPage = graph.createNode(labels=["Branded"], properties= %*{"url": "https://site.com/about", "title":"About Title"})

    let internalLink1 = graph.createLink(label="InternalOutbound", incoming=homePage, outgoing=aboutPage)

    # code here :)