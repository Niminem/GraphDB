# This parsing isn't going to cut it. Nim's html parser really sucks.
# option 1: get rendered source for URL & extract that data during Screaming Frog crawl (if has this functionality)
# option 2: wrap and use Tidy library (or executable)
# option 3: use webdriver to visit all URLs w/ 200 status code and get rendered source through JS script injection
# option 4: develop spec-compliant HTML parser in Nim

import std/htmlparser
import std/xmltree  # To use '$' for XmlNode
import std/strtabs  # To access XmlAttributes
import std/[tables, parsecsv, os, strutils, unidecode, sequtils]


proc innerTextNew*(n: XmlNode): string =
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

    result = body.innerTextNew.splitWhitespace()#splitLines()
    # 0. unidecode
    # 1. replace special characters w/ space (everything aside from #s, letters, spaces)
    # 2. lowercase all letters
    # 3. split by whitespace & work on new sequence to add 'terms' to result seq[string]
    for i in 0 .. result.high:
        let tokens = result[i].unidecode # 0
        if not all(tokens, proc (s: char): bool = s == ' ') and tokens != "":
            var term: string
            for token in tokens.toLower:
                if token in {'a' .. 'z', '0' .. '9', ' '}:
                    term.add(token)
                else: term.add(' ')
            for str in term.splitWhitespace():
                result.add(str)



when isMainModule:
    var
        htmlSrc: string
        p: CsvParser
    p.open(currentSourcePath.parentDir() / "custom_extraction_all.csv")
    p.readHeaderRow()
    while p.readRow:
        if p.rowEntry("Address") == "https://www.lightchiropractic.sg/":
            htmlSrc = p.rowEntry("html_tag 1")
            break
    
    let htmlTokens = tokenizeHtmlBody(htmlSrc)
    echo htmlTokens.len
    
    let terms = splitWhitespace "singapore chiropractor"
    let match1 = htmlTokens.find(terms[0])
    if match1 != -1:
        echo "finding 'chiropractor singapore' in page source, by looking for each token consequtivley"
        var match2 = htmlTokens[match1 + 1]
        echo "match 1: " & htmlTokens[match1]
        echo "match 2: " & match2
