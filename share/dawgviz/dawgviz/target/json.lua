-- TODO: Do proper JSON escaping (`%q` is insufficient).
local buffer = require "string.buffer"

local ipairs = ipairs

prologue      = "[{"
substring_key = "s"
first_pos_key = "p"
len_key       = "n"
clone_key     = "c"
link_key      = "l"
next_key      = "d"
epilogue      = "}]"

function emit_prologue()
  print(prologue)
end

o = buffer.new()

function Node:get_id()
  return self.id
end

function Node:emit_substring()
  if substring_key then
    o:putf(",\n%q:%q", substring_key, input:sub(self.first_pos - self.len + 1, self.first_pos))
  else
    o:putf(",\n%q:%d", len_key, self.len)
  end
end

function Node:emit_first_pos()
  o:putf(",\n%q:%d", first_pos_key, self.first_pos - 1)
end

function Node:emit_clone()
  if self.clone then
    o:putf(",\n%q:true", clone_key)
  end
end

function Node:emit_link()
  if self.link then
    o:putf(",\n%q:%s", link_key, self.link:get_id())
  end
end

function Node:emit_next()
  o:putf(",\n%q:", next_key)
  local sep = 0x7B
  for c, target in pairs(self.next) do
    o:putf("%c%q:%s", sep, c, target:get_id())
    sep = 0x2C
  end
  o:put(sep == 0x2C and "}" or "{}")
end

Node.field_emitters = {"emit_substring", "emit_first_pos", "emit_clone", "emit_link", "emit_next"}

function Node:emit()
  for _, e in ipairs(self.field_emitters) do
    self[e](self)
  end
  o:skip(2)
  print(o:get())
end

function emit_all_nodes(nodes)
  for i, node in ipairs(nodes) do
    if i ~= 1 then print "},{" end
    node:emit()
  end
end

function emit_epilogue()
  print(epilogue)
end

emitters = {"emit_prologue", "emit_all_nodes", "emit_epilogue"}

function emit(s, nodes)
  input = s
  local g = _G
  for _, e in ipairs(emitters) do
    g[e](nodes)
  end
end
