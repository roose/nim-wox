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
  wp.add("Github", # title
         "How people build software", # subtitle
         "Images\\gh.png", # icon
         "", # context data, leave blank if you don't need context menu
         "openUrl", # method
         "https://github.com/", # method params
         false # don't hide
  )
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
  wp.add("postcss", # title
         "Tool for transforming style", # subtitle
         "Images\\postcss.png", # icon
         "https://www.npmjs.com/package/postcss", # context data
         "openUrl", # method
         "https://github.com/postcss/postcss", # method params
         false # don't hide
  )
  # send output to Wox
  echo wp.results()

proc contextmenu(wp: Wox, params: varargs[string]) =
  # proc for context menu action
  wp.add("Open npm page", # title
         "", # subtitle, leave blank
         "Images\\npm.png", # icon
         "", # context data, leave blank
         "openUrl", # method
         params[0], # method params, given context data from query method
         false # don't hide
  )
  # send output to Wox
  echo wp.results()

proc openUrl(wp: Wox, params: varargs[string]) =
  # open url in default browser
  openDefaultBrowser(params[0])

when isMainModule:
  # url for help magic action
  var wp = newWox("http://roose.github.io/nim-wox/wox.html")
  # register `query` and `openUrl` for call from Wox
  wp.register("query", query)
  wp.register("openUrl", openUrl)
  # register `contextmenu` for call from Wox context menu by pressing Shift+Enter
  wp.register("contextmenu", contextmenu)
  # run called proc
  wp.run()
```
**Attention:** `newWox` is generating `info.png` and `delete.png` in the `Images` folder(if they don't exist).
**Attention #2:** Wox now wrong show icons in context menu, [issue](https://github.com/Wox-launcher/Wox/issues/3223)

## Documentation

[Documentation](http://roose.github.io/nim-wox/wox.html)

## Tests

`nimble tests`

## [Changelog](changelog.md)

## Licensing

The code and documentation are released under the MIT Licence. See the bundled [LICENSE](https://github.com/roose/nim-wox/blob/master/LICENSE) file for details.