{.this: self.}

import strfmt
import tables


# Suffix Automaton implementation.
type
    NodePtr = ptr Node

    Node = object
        length: int
        firstPos: int
        isClone: bool
        done: bool
        next: Table[char, NodePtr]
        link: NodePtr


proc init(self: var Node) =
    length = 0
    firstPos = -1
    isClone = false
    done = false
    next = initTable[char, NodePtr]()
    link = nil


proc init(self: var Node; length: int) =
    self.length = length
    isClone = false
    done = false
    next = initTable[char, NodePtr]()


proc init(self: var Node; node: Node) =
    self = node


let
    s = stdin.readLine()
    n = len s

var
    lastNode = -1
    nodes = newSeq[Node](n shl 1)


proc newNode(arg: int | Node): NodePtr =
    inc lastNode
    init nodes[lastNode], arg
    addr nodes[lastNode]


proc add(root: var Node; c: char; last: NodePtr): NodePtr =
    var node = last
    result = newNode(node.length + 1)
    result.firstPos = node.length
    while node != nil and not node.next.hasKeyOrPut(c, result):
        node = node.link
    if node == nil:
        result.link = addr root
    else:
        var q = node.next[c]
        if q.length == node.length + 1:
            result.link = q
        else:
            var clone = newNode q[]
            clone.isClone = true
            clone.length = node.length + 1
            q.link = clone
            result.link = clone
            while true:
                node.next.withValue(c, value) do:
                    if value[] != q:
                        break
                    value[] = clone
                do: # Not found.
                    break
                node = node.link
                if node == nil:
                    break


# DOT file generation.
proc writeformat(o: var Writer; node: NodePtr; fmt: Format) =
    write o, 'n'
    writeformat o, cast[uint](node), fmt


proc escape(c: char): string =
    case c
    of '\t':
        "\\\t"
    of '"':
        "\\\""
    of '\\':
        "\\\\"
    else:
        var s = "."
        s[0] = c
        s


proc label(self: Node): string =
    result = "\""
    for i in firstPos - length + 1 .. firstPos:
        result &= escape s[i]
    result &= '"'


proc printMeta(self: var Node) =
    var attrs = @[["label", self.label]]
    if isClone:
        attrs.add(["shape", "Mcircle"])
    printlnfmt "    {:X} [{:a| |=}]", addr self, attrs


proc echo(self: var Node) =
    if not done:
        done = true
        for c, node in next:
            printlnfmt "    {:X} -> {:X} [label=\"{}\"]", addr self, node, escape c
            echo node[]


var root: Node
init root
var node = addr root
for c in s:
    node = root.add(c, node)

echo "digraph {\n    node [shape=circle]"
printMeta root
for i in 0..lastNode:
    printMeta nodes[i]
echo root
echo "    edge [style=dotted dir=back arrowtail=empty]"
for i in 0..lastNode:
    printlnfmt "    {:X} -> {:X}", nodes[i].link, addr nodes[i]
echo '}'
