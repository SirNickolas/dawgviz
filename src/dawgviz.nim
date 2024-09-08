from   std/json import nil
from   std/os import nil
from   std/strutils import nil
import std/tables
import ./dawgviz/dawg
import ./dawgviz/private/lua
when not declared stdin:
  import std/syncio

const luaScriptDir {.strDefine.} = "../share/dawgviz"

proc panic(lu: LuaState): cint {.cdecl, discardable.} =
  quit lu.`$` -1

proc escapeJson(lu: LuaState): cint {.cdecl.} =
  lu.pushLString json.escapeJson lu.checkNimString 1
  1

proc luaopen_string2(lu: LuaState): cint {.cdecl.} =
  lu.getGlobal "string"
  lu.pushCClosure escapeJson
  lu.setField -2, "escape_json"
  1

proc prepare(lu: LuaState; target: string; files, patches: openArray[string]) =
  discard lu.atPanic panic # Our tiny app can afford registering a global panic handler.
  lu.openLibs
  lu.pop lu.luaOpen_string2

  lu.getGlobal "package"
  lu.getField -1, "path"
  lu.pushLString ';' & os.absolutePath(luaScriptDir, os.getAppDir()) & "/?.lua"
  lu.concat 2
  lu.setField -2, "path"
  lu.pop 1 # package

  lu.createTable 0, 1
  lu.pushValue -1
  lu.setField -1, "__index"
  lu.setGlobal "Node"

  if target != "-":
    lu.getGlobal "require"
    lu.pushLString "dawgviz.target." & target
    lu.call 1, 0
  for f in files:
    if lu.loadFile(f.cstring) != 0:
      lu.panic
    lu.call 0, 0
  for p in patches:
    if lu.loadBuffer(p, "-e") != 0:
      lu.panic
    lu.call 0, 0

  lu.getGlobal "emit"
  case lu.luaType -1 # Check it right after loading files.
    of 0:
      var msg = "Global function `emit` is not found."
      if files.len + patches.len != 0:
        msg &= """ Did you forget to `require "dawgviz.target.dot"`?"""
      quit msg
    of 1 .. 4: quit "Global `emit` is not a function."
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
      lu.pushLString s
      lu.rawGetI -4, dawg.indexOf(nextNode).cint + 1
      lu.rawSet -3
    lu.setField -2, "next"
    if node.link != nil:
      lu.rawGetI -2, dawg.indexOf(node.link).cint + 1
      lu.setField -2, "link"
    lu.pop 1

proc dawgviz(files: seq[string]; target = ""; eval: seq[string] = @[]) =
  let lu = luaL_newState()
  lu.prepare if target.len != 0: target elif files.len == 0: "dot" else: "-", files, eval
  let input = stdin.readLine()
  lu.pushLString input
  lu.pushDawg initDawg input
  lu.call 2, 0

when isMainModule:
  import cligen

  clCfg.version = static staticRead"../dawgviz.nimble".fromNimble"version"
  clCfg.hTabCols = @[clOptKeys, clDescrip]
  clCfg.sepChars = {'='}
  clCfg.longPfxOk = false
  clCfg.noHelpHelp = true
  cgParseErrorExitCode = 2
  dispatch(
    dawgviz,
    usage = "$command [-T<fmt>] [-e<code>...] [<custom-formatter>...]\n${doc}Options:\n$options",
    help = {
      "version": "Print version.",
      "target":  "Select output format (or `-` for none).",
      "eval":    "Evaluate Lua code after loading everything.",
    },
    short = {
      "target": 'T',
      "version": 'V',
    },
  )
