# Package

version       = "1.1.0"
author        = "roose"
description   = "Helper library for writing Wox plugins in Nim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.19.0"
requires "unicodeplus >= 0.8.0"

task tests, "Run Wox.nim tester":
  exec "nim c -r tests/woxtests"