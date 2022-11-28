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

proc newLabeledPropertyGraph*(): LabeledPropertyGraph =
    result


# NODES
proc addNode*(graph: var LabeledPropertyGraph; nodeId: string = $genOid();
                labels: openArray[string] = @[]; properties: JsonNode = newJNull()): NodeID {.discardable.} =
                                                                        # discardable (returns for chaining purposes)
    # add node to Node table with a unique ID (key)
    graph.nodes[nodeId] = Node(properties: properties, labels: labels.toHashSet)
    # add node lables to Label table
    for label in labels:
        if graph.labels.hasKeyOrPut(label, toHashSet([nodeId])):
            graph.labels[label].incl(nodeId)
    
    result = nodeId


proc delNode*(graph: var LabeledPropertyGraph; nodeId: string;) =

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

# //data stored with this direction
# CREATE (p:Person)-[:LIKES]->(t:Technology)

proc addLink*(graph: var LabeledPropertyGraph; label, incoming, outgoing: string;
                properties: JsonNode = newJNull()): LinkID {.discardable.} =
    # generate unqiue Link ID
    let linkId = $genOid()
    # add new Link to graph
    graph.links[linkId] = Link(label: label, head: incoming, tail: outgoing, properties: properties)
    # add Link label to Labels table (if not exist) & add Link ID to label's set in Label table
    if graph.labels.hasKeyOrPut(label, toHashSet([linkId])):
        graph.labels[label].incl(linkId)
    # add Link ID to incoming set in Node ID (incoming)
    graph.nodes[incoming].incoming.incl(linkId)
    # add Link ID to outgoing set in Node ID (outgoing)
    graph.nodes[outgoing].outgoing.incl(linkId)

    result = linkId


when isMainModule:
    var graph = newLabeledPropertyGraph()
    let
                                                # TODO: remove nodeId as param, if we need something like a name (ex. URL) use 'properties'
        homePage = graph.addNode(labels=["Homepage"], properties= %*{"url": "https://site.com/", "title":"Home Title"}) #nodeId="https://site.com/", labels=["Homepage"])
        aboutPage = graph.addNode(labels=["Branded"], properties= %*{"url": "https://site.com/about", "title":"About Title"}) #nodeId="https://site.com/about", labels=["Branded"])
        contactPage = graph.addNode(labels=["Branded"], properties= %*{"url": "https://site.com/contact", "title":"Contact Title"})#nodeId="https://site.com/contact", labels=["Branded"])

    let
        internalLink1 = graph.addLink(label="InternalOutbound", incoming=homePage, outgoing=aboutPage)
        internallink2 = graph.addLink(label="InternalOutbound", incoming=homePage, outgoing=contactPage)
        internalLink3 = graph.addLink(label="InternalOutbound", incoming=aboutPage, outgoing=contactPage)
    
    echo graph.nodes
    echo "-----\n"
    echo graph.labels
    echo "-----\n"
    echo graph.links
    echo "-----\n"

    echo "URLs that have INTERNAL_LINKS from HOMEPAGE"
    let match = collect(newseq):
        for linkIdx in graph.labels["InternalOutbound"]:
            if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
    echo "match found: " & $match
   
    echo "-----\n"
    echo graph.links[internalLink1]
    echo "-----\n"

    echo "deleting homepage node"
    graph.delNode(homePage)

    echo "-----\n"
    let match2 = collect(newseq):
        for linkIdx in graph.labels["InternalOutbound"]:
            if graph.links[linkIdx].head == homePage: graph.nodes[graph.links[linkIdx].tail].properties["url"]
    echo "URLs that have INTERNAL_LINKS from HOMEPAGE"
    echo "match found: " & $match2