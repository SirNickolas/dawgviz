version     = "0.1.1"
author      = "Nickolay Bukreyev"
description = "Suffix Automaton Visualizer"
license     = "GPL-3"

requires(
  "nim >= 1.0.0",
  "cligen >= 1.5.0",
)

srcDir  = "src"
binDir  = "bin"
bin     = @["dawgviz"]
installDirs = @["share"]
