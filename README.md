# nim-wox

Helper library for writing [Wox](http://getwox.com/) plugins in [Nim](http://nim-lang.org/)

## Contents

- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [Tests](#tests)
- [Licensing](#licensing)

## Installation

`nimble install wox`

## Usage

```Nimrod
import browsers
import wox

proc query(query: string) =
  # create a global Wox object
  var wp = newWox()
  # add an item to Wox
  wp.add("Github", "How people build software", "Images\\gh.png",
          "openUrl", "https://github.com/", false)
  # send output to Wox
  echo wp.results()
  
proc openUrl(url: string) =
  # open url in default browser
  openDefaultBrowser(url)
  
when isMainModule:
  # register `query` and `openUrl` for call from Wox
  register("query", query)
  register("openUrl", openUrl)
  # run called proc
  run()
```

## Documentation

[Documentation](http://roose.github.io/nim-wox/wox.html)

## Tests

`nimble tests`

## Licensing

The code and documentation are released under the MIT Licence. See the bundled [LICENSE](https://github.com/roose/nim-wox/blob/master/LICENSE) file for details.