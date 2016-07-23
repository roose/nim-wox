# Package

name          = "wox"
version       = "0.4.0"
author        = "roose"
description   = "Helper library for writing Wox plugins in Nim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.13.0"

task tests, "Run Wox.nim tester":
  exec "nim c -r tests/woxtests"