## http://e-maxx.ru/algo/suffix_automata

import std/tables
when not declared assert:
  import std/assertions

type
  DawgNode* = object
    len*: int
    firstPos*: int
    clone*: bool
    next*: Table[char, ptr DawgNode]
    link*: ptr DawgNode

  Dawg* = object
    nodes: seq[DawgNode]
    last: ptr DawgNode
    when compileOption"assertions":
      maxLen: int

when NimMajor >= 2:
  template unsafeAddr(x): untyped = addr x

func nodes*(self: Dawg): lent seq[DawgNode] {.inline.} = self.nodes

func indexOf*(self: Dawg; node: ptr DawgNode): int =
  let base = cast[int](unsafeAddr self.nodes[0])
  let p = cast[int](node)
  assert p >=% base and p <% base + self.nodes.len * sizeOf DawgNode
  return (p - base) div sizeOf DawgNode

func initDawg*(maxLen: int): Dawg =
  result.nodes = newSeqOfCap[DawgNode] maxLen shl 1
  result.nodes &= DawgNode(firstPos: -1)
  result.last = addr result.nodes[0]
  when compileOption"assertions":
    result.maxLen = maxLen shl 1

proc addNode(self: var Dawg; node: DawgNode): ptr DawgNode =
  let i = self.nodes.len
  when compileOption"assertions":
    assert i < self.maxLen
  self.nodes &= node
  addr self.nodes[i]

proc add*(self: var Dawg; c: char) =
  var node = self.last
  let newNode = self.addNode DawgNode(len: node.len + 1, firstPos: node.len)
  self.last = newNode
  while not node.next.hasKeyOrPut(c, newNode):
    node = node.link
    if node == nil:
      newNode.link = addr self.nodes[0]
      return

  let q = node.next[c]
  if q.len == node.len + 1:
    newNode.link = q
  else:
    let clone = self.addNode q[]
    clone.len = node.len + 1
    clone.clone = true
    q.link = clone
    newNode.link = clone
    while true:
      node.next.withValue c, value:
        if value[] != q:
          return
        value[] = clone
      do: # Not found.
        return
      node = node.link
      if node == nil:
        return

func initDawg*(s: openArray[char]): Dawg =
  result = initDawg s.len
  for c in s:
    {.noSideEffect.}:
      result.add c
