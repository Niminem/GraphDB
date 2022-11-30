import std/[oids, tables, sets, json, sugar]

type
    NodeID* = string
    LinkID* = string
    Node* = object
        outgoing*, incoming*, labels*: HashSet[string]
        properties*: JsonNode
    Link* = object
        lType*: string # link (relationship) type
        head*, tail*: string
        properties*: JsonNode
    NodeTable* = Table[string, Node]
    LinkTable* = Table[string, Link]
    LabelTable* = Table[string, HashSet[string]]
    TypeTable* = Table[string, HashSet[string]]
    NodePropertyTable* = Table[string, HashSet[string]]
    LinkPropertyTable* = Table[string, HashSet[string]]
    LabeledPropertyGraph* = object
        # fields are 'indexes', we have 6 total
        nodes*: NodeTable
        links*: LinkTable
        labels*,types*,nProperties*,lProperties*: Table[string, HashSet[string]]

# GRAPHS
proc newLabeledPropertyGraph*(): LabeledPropertyGraph =
    result
    # TODO: robust graph creation w/ initial support for parsing & processing CSV files



# NODES
proc createNode*(graph: var LabeledPropertyGraph; labels: openArray[string] = @[];
                    properties: JsonNode = newJObject()): NodeID {.discardable.} =
    # generate unqiue Node ID
    let nodeId = $genOid()
    # add node to Node table with a unique ID (key)
    graph.nodes[nodeId] = Node(properties: properties, labels: labels.toHashSet)
    # add node lables to Label table
    for label in labels:
        if graph.labels.hasKeyOrPut(label, toHashSet([nodeId])):
            graph.labels[label].incl(nodeId)
    # add node properties to Node Property Table (if exists)
    for property in properties.keys:
        if graph.nProperties.hasKeyOrPut(property, toHashSet([nodeId])):
            graph.nProperties[property].incl(nodeId)
    # return discardable Node ID for chaining/eval purposes
    return nodeId

proc deleteLink*(graph: var LabeledPropertyGraph; linkId: string) # forward declaration
proc deleteNode*(graph: var LabeledPropertyGraph; nodeId: string;) = # needs robust exception handling & return value at some point

    # removes all Links and labels to Links connecting to/from this node
    for linkId in (graph.nodes[nodeId].outgoing + graph.nodes[nodeId].incoming):
        graph.types[graph.links[linkId].lType].excl(linkId) # deletes reference of Link from Label table
        graph.deleteLink(linkId) # graph.links.del(linkId) # deletes all connected link IDs/keys from Link Table (no broken link rule)
    # delete node ID from all properties (and property if now empty)
    for property in graph.nodes[nodeId].properties.keys:
        graph.nProperties[property].excl(nodeId)
        if graph.nProperties[property].len == 0: graph.nProperties.del(property)

    # deletes node ID from all labeled sets
    for label in graph.nodes[nodeId].labels:
        graph.labels[label].excl(nodeId)
    # delete node from Node table
    graph.nodes.del(nodeId)



# LINKS
proc createLink*(graph: var LabeledPropertyGraph; lType, incoming, outgoing: string;
                properties: JsonNode = newJObject()): LinkID {.discardable.} =
    # generate unqiue Link ID
    let linkId: NodeID = $genOid()
    # add new Link to graph
    graph.links[linkId] = Link(ltype: lType, head: incoming, tail: outgoing, properties: properties)
    # add Link label to Labels table (if not exist) & add Link ID to label's set in Label table
    if graph.types.hasKeyOrPut(lType, toHashSet([linkId])):
        graph.types[lType].incl(linkId)
    # add Link properties to Link Property Table (if exists)
    for property in properties.keys:
        if graph.lProperties.hasKeyOrPut(property, toHashSet([linkId])):
            graph.lProperties[property].incl(linkId)
    # add Link ID to incoming set in Node ID (incoming)
    graph.nodes[incoming].incoming.incl(linkId)
    # add Link ID to outgoing set in Node ID (outgoing)
    graph.nodes[outgoing].outgoing.incl(linkId)
    # return discardable Link ID for chaining/eval purposes
    return linkId

proc deleteLink*(graph: var LabeledPropertyGraph; linkId: string) = # needs robust exception handling & return value at some point
    # delete linkId from label in Label table
    graph.types[graph.links[linkId].lType].excl(linkId)
    # delete node ID from all properties (and property if now empty)
    for property in graph.links[linkId].properties.keys:
        graph.lProperties[property].excl(linkId)
        if graph.lProperties[property].len == 0: graph.lProperties.del(property)
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

    let internalLink1 = graph.createLink(lType="InternalOutbound", incoming=homePage, outgoing=aboutPage, properties= %*{"key":"val"})

    # code here :)