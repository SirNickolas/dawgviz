local buffer = require "string.buffer"

local pairs = pairs
local tostring = tostring
local format = string.format
local concat = table.concat

local tmp = buffer.new()

function concat_attrs(attrs)
  for k, v in pairs(attrs) do
    tmp:putf(" %s=%q", k, v)
  end
  tmp:skip(1)
  return tmp:get()
end

function emit_with_attrs(subject, attrs)
  local a = concat_attrs(attrs)
  if a ~= "" then
    print(subject.." ["..a..']')
  end
end

prologue    = "digraph {"
node_attrs  = {shape = "circle"}
clone_attrs = {shape = "Mcircle"}
edge_attrs  = { }
link_attrs  = {style = "dotted", dir = "back", arrowtail = "empty"}
epilogue    = "}"

function emit_prologue()
  print(prologue)
end

function emit_common_node_attrs()
  emit_with_attrs("node", node_attrs)
end

function Node:get_id()
  return self.id
end

function Node:get_attrs()
  local result = { }
  if self.clone then
    for k, v in pairs(clone_attrs) do
      result[k] = v
    end
  end
  return result
end

function Node:emit()
  local attrs = self:get_attrs()
  attrs.label = input:sub(self.first_pos - self.len + 1, self.first_pos)
  emit_with_attrs(self:get_id(), attrs)
end

function emit_all_nodes(nodes)
  for _, node in ipairs(nodes) do
    node:emit()
  end
end

function emit_common_edge_attrs()
  emit_with_attrs("edge", edge_attrs)
end

function Node:emit_edges()
  for c, target in pairs(self.next) do
    print(format("%s -> %s [label=%q]", self:get_id(), target:get_id(), c))
    if not target.processed then
      target.processed = true -- HACK.
      target:emit_edges()
    end
  end
end

function emit_all_edges(nodes)
  nodes[1]:emit_edges()
end

function emit_common_link_attrs()
  emit_with_attrs("edge", link_attrs)
end

function Node:emit_link()
  print(self.link:get_id().." -> "..self:get_id())
end

function emit_all_links(nodes)
  for i = 2, #nodes do
    nodes[i]:emit_link()
  end
end

function emit_epilogue()
  print(epilogue)
end

emitters = {
  "emit_prologue",
  "emit_common_node_attrs",
  "emit_all_nodes",
  "emit_common_edge_attrs",
  "emit_all_edges",
  "emit_common_link_attrs",
  "emit_all_links",
  "emit_epilogue",
}

function emit(s, nodes)
  input = s
  local g = _G
  for _, e in ipairs(emitters) do
    g[e](nodes)
  end
end
