import strformat
import strutils
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
    self.length = 0
    self.firstPos = -1
    self.isClone = false
    self.done = false
    self.next = initTable[char, NodePtr]()
    self.link = nil


proc init(self: var Node; length: int) =
    self.length = length
    self.isClone = false
    self.done = false
    self.next = initTable[char, NodePtr]()


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


var root: Node
init root
var node = addr root
for c in s:
    node = root.add(c, node)


# DOT file generation.
proc id(self: var Node): uint =
    cast[uint](addr self)


proc emitMeta(self: var Node) =
    let
        label = escape s[self.firstPos - self.length + 1 .. self.firstPos]
        shape = if self.isClone: " shape=Mcircle" else: ""
    stdout.write &"{self.id} [label={label}{shape}]\n"


proc dump(self: var Node) =
    for c, node in self.next:
        stdout.write &"{self.id} -> {node[].id} [label={escape $c}]\n"
        if not node.done:
            node.done = true
            dump node[]


stdout.write "digraph {\nnode [shape=circle]\n"
emitMeta root
for i in 0..lastNode:
    emitMeta nodes[i]
dump root
stdout.write "edge [style=dotted dir=back arrowtail=empty]\n"
for i in 0..lastNode:
    stdout.write &"{nodes[i].link[].id} -> {nodes[i].id}\n"
stdout.write "}\n"
