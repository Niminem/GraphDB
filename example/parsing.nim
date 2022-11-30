## Not part of the library, I will need to have a macro (query lang DSL) and support
## the user's unique needs with allowing control for Node/Link insertions.
## 
import std/[
    parsecsv, tables, sequtils, jsonutils, sets, strutils, sugar, json, os,
    htmlparser, xmltree, strtabs, unidecode]
import ../src/[graph_db, query_lang]

# CSV STUFF ------------------------------------------------------------------------------------------------
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

proc csvToNodeProperty*(graph: var LabeledPropertyGraph; file: string; hasHeaders: bool) = 
    var p: CsvParser
    p.open(file)
    if hasHeaders: p.readHeaderRow()
    while p.readRow():
        let
            address = p.rowEntry("Address")
        graph.nodes[graph.getNodeIdByPropertyVal(property="Address",value=address)].properties.add("Src", %*p.rowEntry("html_tag 1"))
    p.close()



# when isMainModule:
#     import times

#     var graph = newLabeledPropertyGraph()

#     var start = getTime()
#     graph.csvToNodes(currentSourcePath.parentDir / "csv_files" / "internal_all.csv", true)
#     graph.csvToLinks(currentSourcePath.parentDir / "csv_files" / "all_inlinks.csv", true)
#     graph.csvToNodeProperty(currentSourcePath.parentDir / "csv_files" / "custom_extraction_all.csv", true)
#     var finish = getTime()
#     echo "Elapsed time: " & $(start - finish) # 1.5 - 1.9 seconds avg
#     echo graph.nodes.len
#     var count = collect(newSeq):
#         for n in graph.nodes.values:
#             if n.properties.hasKey("Src"): 1
#     echo count.len
#     echo graph.links.len
# -----------------------------------------------------------------------------------------------------------

# HTML STUFF ------------------------------------------------------------------------------------------------
# This parsing isn't going to cut it. Nim's html parser really sucks.
# option 1: get rendered source for URL & extract that data during Screaming Frog crawl (if has this functionality)
# option 2: wrap and use Tidy library (or executable)
# option 3: use webdriver to visit all URLs w/ 200 status code and get rendered source through JS script injection
# option 4: develop spec-compliant HTML parser in Nim


proc getText*(n: XmlNode): string =
    ## Gets the inner text of `n`:
    ##
    ## - If `n` is `xnText` or `xnEntity`, returns its content.
    ## - If `n` is `xnElement`, runs recursively on each child node and
    ##   concatenates the results.
    ## - Otherwise returns an empty string.

    proc worker(res: var string, n: XmlNode) =
        # TODO: check if need to handle <br> tags (like add " " around them or something)
        case n.kind
        of xnText, xnEntity:
            res.add(n.text)
        of xnElement:
            if n.htmlTag == tagBr: res.add(" ") # handle <br> tags
            if n.htmlTag notin {tagScript, tagNoscript, tagStyle}:
                for sub in n.items:
                    worker(res, sub)
        else:
            discard

    result = ""
    worker(result, n)


proc tokenizeHtmlBody*(htmlSrc: string): seq[string] =
    # get body tag
    var body = parseHtml(htmlSrc).findAll("body")[0]
    
    # TODO: get content from body, in order, as a sequence of tokens.
    # this way, we can search for both single terms and "ordered phrases"
    # and find matches within the sequence using indexes ex:
    # searching match for "seo consultant" -> ["seo", "consultant"] ->
    # 1.) finds match for "seo" and gets index
    # 2.) checks index + 1 for "consultant"
    # 3.) returns true

    var test = body.getText.splitWhitespace()#splitLines()
    # 0. unidecode
    # 1. replace special characters w/ space (everything aside from #s, letters, spaces)
    # 2. lowercase all letters
    # 3. split by whitespace & work on new sequence to add 'terms' to result seq[string]
    for i in 0 .. test.high:

        let tokens = test[i].unidecode
        if not all(tokens, proc (s: char): bool = s == ' ') and tokens != "":
            var term: string
            for token in tokens.toLower:
                if token in {'a' .. 'z', '0' .. '9', ' '}:
                    term.add(token)
                else: term.add(' ')

            for str in term.splitWhitespace():
                result.add(str)

# when isMainModule:
#     var
#         htmlSrc: string
#         p: CsvParser
#     p.open(currentSourcePath.parentDir() / "csv_files" / "custom_extraction_all.csv")
#     p.readHeaderRow()
#     while p.readRow:
#         if p.rowEntry("Address") == "https://www.lightchiropractic.sg/":
#             htmlSrc = p.rowEntry("html_tag 1")
#             break
#     p.close()

#     let htmlTokens = tokenizeHtmlBody(htmlSrc)
#     # for token in htmlTokens:
#     #     echo token & $token.len
    
#     let terms = splitWhitespace "singapore chiropractor"
#     let match1 = htmlTokens.find(terms[0])
#     if match1 != -1:
#         echo "finding 'singapore chiropractor' in page source, by looking for each token consequtivley"
#         var match2 = htmlTokens[match1 + 1]
#         echo "match 1: " & htmlTokens[match1]
#         echo "match 2: " & match2

# -----------------------------------------------------------------------------------------------------------