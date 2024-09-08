const luaJitLib {.strDefine.} = "libluajit(|-5.1).so(|.2|.1|.0)"

type
  LuaState* {.incompleteStruct.} = ptr object
  LuaCFunction* = proc (lu: LuaState): cint {.cdecl.}

const luaGlobalsIndex* = -10002

{.push cdecl, sideEffect, dynlib: luaJitLib.}

proc luaType*(lu: LuaState; idx: cint): cint {.importc: "lua_type".}

{.push importc: "lua_$1".}
proc settop*(lu: LuaState; idx: cint)
proc atpanic*(lu: LuaState; panicf: LuaCFunction): LuaCFunction
proc tolstring*(lu: LuaState; idx: cint; len: ptr int): ptr UncheckedArray[char]
proc pushvalue*(lu: LuaState; idx: cint)
proc pushinteger*(lu: LuaState; n: int)
proc pushboolean*(lu: LuaState; b: cint)
proc pushcclosure*(lu: LuaState; fn: LuaCFunction; n: cint = 0)
proc createtable*(lu: LuaState; narr, nrec: cint)
proc rawset*(lu: LuaState; idx: cint)
proc rawgeti*(lu: LuaState; idx, i: cint)
proc rawseti*(lu: LuaState; idx, i: cint)
proc getfield*(lu: LuaState; idx: cint; k: cstring)
proc setfield*(lu: LuaState; idx: cint; k: cstring)
proc setmetatable*(lu: LuaState; idx: cint): cint {.discardable.}
proc concat*(lu: LuaState; n: cint)
proc call*(lu: LuaState; nargs, nresults: cint)
{.pop.} # importc

proc pushNimString*(lu: LuaState; s: openArray[char]) {.importc: "lua_pushlstring".}
proc luaL_newstate*: LuaState {.importc.}

{.push importc: "luaL_$1".}
proc openlibs*(lu: LuaState)
proc checklstring*(lu: LuaState; numArg: cint; len: ptr int): ptr UncheckedArray[char]
{.pop.} # importc

{.pop.} # cdecl, sideEffect, dynlib

when NimMajor >= 2:
  template unsafeAddr(x): untyped = addr x

func toString*(p: openArray[char]): string =
  if p.len != 0:
    result = newString p.len
    copyMem addr result[0], unsafeAddr p[0], p.len

proc `$`*(lu: LuaState; idx: cint): string =
  var n: int
  let p = lu.toLString(idx, addr n)
  p.toOpenArray(0, n - 1).toString

proc checkNimString*(lu: LuaState; numArg: cint): string =
  var n: int
  let p = lu.checkLString(numArg, addr n)
  p.toOpenArray(0, n - 1).toString

proc pop*(lu: LuaState; n: cint) {.inline.} =
  lu.setTop -n - 1

proc getGlobal*(lu: LuaState; k: cstring) {.inline.} =
  lu.getField luaGlobalsIndex, k

proc setGlobal*(lu: LuaState; k: cstring) {.inline.} =
  lu.setField luaGlobalsIndex, k
