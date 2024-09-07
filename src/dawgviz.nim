from   std/os import nil
from   std/strutils import nil
import std/tables
import ./dawgviz/dawg
import ./dawgviz/private/lua
when not declared stdin:
  import std/syncio

const luaScriptDir {.strDefine.} = "../share/dawgviz"

proc panic(lu: LuaState): cint {.cdecl.} =
  quit lu.`$` -1

proc prepare(lu: LuaState; target: string) =
  discard lu.atPanic panic # Our tiny app can afford registering a global panic handler.
  lu.openLibs

  lu.getGlobal "package"
  lu.getField -1, "path"
  lu.pushNimString ';' & os.absolutePath(luaScriptDir, os.getAppDir()) & "/?.lua"
  lu.concat 2
  lu.setField -2, "path"
  lu.pop 1 # package

  lu.createTable 0, 1
  lu.pushValue -1
  lu.setField -1, "__index"
  lu.setGlobal "Node"

  if target != "-":
    lu.getGlobal "require"
    lu.pushNimString "dawgviz.target." & target
    lu.call 1, 0

  lu.getGlobal "emit"
  case lu.luaType -1
    of 0: quit "dawgviz: Global function `emit` is not found."
    of 1 .. 4: quit "dawgviz: Global `emit` is not a function."
    else: discard

proc pushDawg(lu: LuaState; dawg: Dawg) =
  lu.createTable dawg.nodes.len.cint, 0
  lu.getGlobal "Node"
  for i, node in dawg.nodes:
    lu.createTable 0, 6
    lu.pushValue -2
    lu.setMetatable -2
    lu.rawSetI -3, cint i + 1
  lu.pop 1 # Node

  var s = "\0"
  for i, node in dawg.nodes:
    lu.rawGetI -1, cint i + 1
    lu.pushInteger i
    lu.setField -2, "id"
    lu.pushInteger node.len
    lu.setField -2, "len"
    lu.pushInteger node.firstPos + 1
    lu.setField -2, "first_pos"
    lu.pushBoolean node.clone.cint
    lu.setField -2, "clone"
    lu.createTable 0, node.next.len.cint
    for c, nextNode in node.next:
      s[0] = c
      lu.pushNimString s
      lu.rawGetI -4, dawg.indexOf(nextNode).cint + 1
      lu.rawSet -3
    lu.setField -2, "next"
    if node.link != nil:
      lu.rawGetI -2, dawg.indexOf(node.link).cint + 1
      lu.setField -2, "link"
    lu.pop 1

proc dawgviz(target = "dot") =
  let lu = luaL_newState()
  lu.prepare target
  let input = stdin.readLine()
  lu.pushNimString input
  lu.pushDawg initDawg input
  lu.call 2, 0

when isMainModule:
  import cligen

  clCfg.version = static staticRead"../dawgviz.nimble".fromNimble"version"
  clCfg.hTabCols = @[clOptKeys, clDflVal, clDescrip]
  clCfg.sepChars = {'='}
  clCfg.longPfxOk = false
  clCfg.noHelpHelp = true
  cgParseErrorExitCode = 2
  dispatch(
    dawgviz,
    help = {
      "version": "Print version.",
      "target": "Select output format (or `-` for none).",
    },
    short = {
      "target": 'T',
      "version": 'V',
    },
  )
