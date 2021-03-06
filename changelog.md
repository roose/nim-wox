## 1.2.1
  - remove params from `ContextData`
  - **Breaking chages** `ContextData` now needs to be specified on adding new item, `add(title, sub, icon, context, method, params, hide)`
## 1.2.0
  - Add context menu support, `ContextData` by default is `params`

  proc name for context menu is `contextmenu`, and need to register `wp.register("contextmenu", contextmenu)`
## 1.1.0
  - Added magic actions
    - Open plugin's cache dir
    - Open plugin's settings dir
    - Delete plugin's cached data
    - Delete plugin's settings
    - Open plugin's dir
    - Open plugin help URL in browser
  - Magic actions can be run with `plugin:` keyword, eg: `plugin:help`
  - `newWox` now may have `help` url for "Open plugin help URL in browser" magic action(default is empty string)
  - `newWox` is generating `info.png` and `delete.png` in the `Images` folder(if they don't exist).
## 1.0.0
- **Breaking chages** replace deprecated procs and requires **nim v0.19.0**
- Replaced deprecated procs
  - In `json` module
    - `getNum` => `getInt`
    - `getFNum` => `getFloat`
    - `getBVal` => `getBool`
  - In `time` module
    - `toSeconds` => `toUnixFloat`
  - In `sets` module
    - `toSet` => `toHashSet`
  - Added `unicode` module
    - `strutils.toLower` => `unicode.toLower`
    - `strutils.isUpper` => `unicode.isUpper`
  - Added `unicodeplus` module
    - `strutils.isDigit` => `unicodeplus.isDigit`
  - Because `toLower`, `isUpper`, `isDigit` is now unicode functions, char in capitalized chars score calculation now is unicode `rune` (`for c in value.runes:`)
  - Removed allredy covered cases from `cmpSort`, `cmpFilter`
  - Created temp variable for `getPluginInfo` due to observable stores warning
- Requires `nim >= 0.19.0`, `unicodeplus >= 0.8.0`