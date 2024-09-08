# dawgviz

Debugging a [suffix automaton][sa]? Try this:

```sh
echo science | dawgviz | dot -Tsvg -o science.svg
```

![Automaton for “science”](https://raw.githubusercontent.com/SirNickolas/dawgviz/master/science.svg)

[sa]: http://e-maxx.ru/algo/suffix_automata


## Installation

1.  Install [Nim][nim].
2.  Install [LuaJIT][lua-jit].

    On a Debian-based distribution, this is as simple as  
    `sudo apt install libluajit-5.1-2`. On Windows, you’ll probably need to copy `luajit.dll`
    to `bin\` after building `dawgviz.exe`.
3.  Install [Graphviz][graphviz].

    Strictly speaking, this is optional, but you won’t be able to generate pictures without it.
4.  Clone this repository.
5.  Run `nimble build -d=release`.
6.  Install the built program.

    On Windows, you’ll need to add `bin\` directory to `PATH`. On Unix, a more idiomatic way is  
    `make PREFIX=~/.local install` or `sudo make install`. **Do not try** to install via Nimble:
    it won’t work.

[nim]: https://nim-lang.org/install.html
[lua-jit]: https://luajit.org/download.html
[graphviz]: https://graphviz.org/download/


## Usage

    Usage:
      dawgviz [-T<fmt>] [-e<code>...] [<custom-formatter>...]
    Options:
      -V, --version   Print version.
      -T=, --target=  Select output format (or `-` for none).
      -e=, --eval=    Evaluate Lua code after loading everything.

### Different output formats

Use `-T` option to choose an output format for the graph. `dot` (used by default) and `json`
formatters are provided:

```sh
echo zoom | dawgviz -Tjson
```

```json
{"i":"zoom","g":[{
"s":"",
"p":-1,
"d":{"o":4,"m":5,"z":1}
},{
"s":"z",
"p":0,
"l":0,
"d":{"o":2}
},{
"s":"zo",
"p":1,
"l":4,
"d":{"o":3}
},{
"s":"zoo",
"p":2,
"l":4,
"d":{"m":5}
},{
"s":"o",
"p":1,
"c":true,
"l":0,
"d":{"m":5,"o":3}
},{
"s":"zoom",
"p":3,
"l":0,
"d":{}
}]}
```

### Configuring the formatter

Use `-e` option to tweak the behaviour of the selected formatter. Its argument is a piece of Lua
code:

```sh
echo zoom | dawgviz -e'graph_attrs.rankdir="LR"'
echo zoom | dawgviz -Tjson -e'substring_key=nil'
echo zoom | dawgviz -Tjson -e'prologue="[{"; epilogue="}]"'
```

Want to know what exactly is available for configuration? Take a look at [dot.lua][dot-lua].
Remember, you can redeclare _anything_.

[dot-lua]: https://github.com/SirNickolas/dawgviz/blob/master/share/dawgviz/dawgviz/target/dot.lua

### Providing a custom formatter

`-e` option works great for small one-time tweaks. If, however, you use the same configuration over
and over again, it may be more convenient to store it in a file.

```lua
#!/usr/bin/env dawgviz

require "dawgviz.target.dot"
node_attrs.shape = "hexagon"
function Node:get_id() return self.id + 1 end -- Emit 1-based indices.
```

```sh
echo zoom | dawgviz my.lua
```

When a custom formatter is passed, `dot` will no longer be loaded implicitly.
