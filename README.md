# nim-wox

![Test nim-wox](https://github.com/roose/nim-wox/workflows/Test%20nim-wox/badge.svg?branch=master)

Helper library for writing [Wox](http://getwox.com/) plugins in [Nim](http://nim-lang.org/)

![demo](images/demo.png)

## Contents

- [nim-wox](#nim-wox)
  - [Contents](#contents)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Documentation](#documentation)
  - [Tests](#tests)
  - [Changelog](#changelog)
  - [Licensing](#licensing)

## Installation

`nimble install wox`

## Usage

```Nim
import browsers, json
import wox

proc query(wp: Wox, params: varargs[string]) =
  # create a global Wox object
  # add an item to Wox
  wp.add("Github", "How people build software", "Images\\gh.png",
          "openUrl", "https://github.com/", false)
  # send output to Wox
  echo wp.results()

proc openUrl(wp: Wox, params: varargs[string]) =
  # open url in default browser
  openDefaultBrowser(params[0])

when isMainModule:
  var wp = newWox("http://roose.github.io/nim-wox/wox.html")
  # register `query` and `openUrl` for call from Wox
  wp.register("query", query)
  wp.register("openUrl", openUrl)
  # run called proc
  wp.run()
```
Context menu example:

```Nim
import browsers, json
import wox

proc query(wp: Wox, params: varargs[string]) =
  # create a global Wox object
  # add an item to Wox
  wp.add("Github", "How people build software", "Images\\gh.png",
          "openUrl", "https://github.com/", false)
  # send output to Wox
  echo wp.results()

proc contextmenu(wp: Wox, params: varargs[string]) =
  # proc for context menu action
  wp.add("Open Github in Firefox", "", "Images\\info.png", "openFirefox", https://github.com/, false)
  echo wp.results()

proc openUrl(wp: Wox, params: varargs[string]) =
  # open url in default browser
  openDefaultBrowser(params[0])

proc openFirefox(wp: Wox, params: varargs[string]) =
  # open url in Firefox(for context menu)
  openFirefoxBrowser(params[0])

when isMainModule:
  # url for help magic action
  var wp = newWox("http://roose.github.io/nim-wox/wox.html")
  # register `query` and `openUrl` for call from Wox
  wp.register("query", query)
  wp.register("openUrl", openUrl)
  # register `contextmenu` for call from Wox context menu by pressing Shift+Enter
  wp.register("contextmenu", contextmenu)
  wp.register("openFirefox", openFirefox)
  # run called proc
  wp.run()
```
**Attention:** `newWox` is generating `info.png` and `delete.png` in the `Images` folder(if they don't exist).

## Documentation

[Documentation](http://roose.github.io/nim-wox/wox.html)

## Tests

`nimble tests`

## [Changelog](changelog.md)

## Licensing

The code and documentation are released under the MIT Licence. See the bundled [LICENSE](https://github.com/roose/nim-wox/blob/master/LICENSE) file for details.