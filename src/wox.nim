## The MIT License (MIT) https://opensource.org/licenses/MIT
##
## Copyright (c) 2016 roose
##
## This module implements helper procs for creating Wox plugins. Example:
##
## .. code-block:: Nim
##
##    import browsers
##    import wox
##
##    proc query(wp: Wox, params: varargs[string]) =
##      # create a global Wox object
##      # add an item to Wox
##      wp.add("Github", "How people build software", "Images\\gh.png",
##              "openUrl", "https://github.com/", false)
##      # send output to Wox
##      echo wp.results()
##
##    proc openUrl(wp: Wox, params: varargs[string]) =
##      # open url in default browser
##      openDefaultBrowser(params[0])
##
##    when isMainModule:
##      var wp = newWox()
##      # register `query` and `openUrl` for call from Wox
##      wp.register("query", query)
##      wp.register("openUrl", openUrl)
##      # run called proc
##      wp.run()
## .
##
## ``Warning:`` settings is JsonNode, on assign new setting value be careful,
## convert it to JsonNode, Example:
##
## .. code-block:: Nim
##    wp.settings["login"] = "john" # Error, because is string
##    wp.settings["login"] = newJString("john") # Right

import tables, os, algorithm, strutils, sequtils, sets, unicode, browsers, base64
import json, marshal, tables, pegs, times

from unicodeplus import isDigit

type
  # Action type for icon
  MagicActionType = enum
    actionPositive, actionNegative

  MagicAction = object
    # Magic Action object
    id: string
    desc: string
    run: string
    actionType: MagicActionType

  PluginInfo* = object
    # Plugin.json info object
    id*: string
    name*: string
    keyword*: seq[string]
    desc*: string
    author*: string
    version*: string
    site*: string
    icon*: string
    file*: string

  Action = object
    ## Wox JsonRPCAction object
    `method`*: string
    parameters*: seq[string]
    dontHideAfterAction*: bool

  Item* = object
    ## Wox item object
    Title*: string
    SubTitle*: string
    IcoPath*: string
    JsonRPCAction*: Action

  Result = object
    # Wox result object
    result*: seq[Item]

  Wox* = ref object
    ## Wox object
    data*: Result
    pluginDir*: string
    plugin*: PluginInfo
    settingsDir*: string
    cacheDir*: string
    settings*: JsonNode
    help*: string

  RpcProc* = proc (self: Wox, params: varargs[string])

  SortBy* = enum
    ## Sort by title or subtitle or title and subtitle
    byTitle, bySub, byTitleSub

# Prefix for magic actions
let
  prefix = "plugin:"
  iconInfo = "iVBORw0KGgoAAAANSUhEUgAAAVgAAAFYCAMAAAAhshRyAAAACXBIWXMAAAsTAAALEwEAmpwYAAAE6WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDIgNzkuMTYwOTI0LCAyMDE3LzA3LzEzLTAxOjA2OjM5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyMC0xMC0xMVQyMjo1MjowMiswNjowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjAtMTAtMTFUMjI6NTM6NTArMDY6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjAtMTAtMTFUMjI6NTM6NTArMDY6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOmFkM2IxZjI1LWM5NWUtNWI0MS04Zjc3LTdjZDllYzhmOTQ4MSIgeG1wTU06RG9jdW1lbnRJRD0ieG1w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"
  iconDelete = "iVBORw0KGgoAAAANSUhEUgAAAVgAAAFYCAMAAAAhshRyAAAACXBIWXMAAAsTAAALEwEAmpwYAAAE6WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDIgNzkuMTYwOTI0LCAyMDE3LzA3LzEzLTAxOjA2OjM5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyMC0xMC0xMVQyMzo0NjoxMCswNjowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjAtMTAtMTFUMjM6NDY6MjkrMDY6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjAtMTAtMTFUMjM6NDY6MjkrMDY6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOmQ1MjYxNDQ2LTE1YzYtNTA0YS04NTk4LTcwYjM2MjA5Y2U1OCIgeG1wTU06RG9jdW1lbnRJRD0ieG1w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"
# magicActions contains added magic actions
var magicActions = initTable[string, MagicAction]()

# name, proc table for call proc
var procs: Table[string, RpcProc] = initTable[string, RpcProc]()

# only for test magic actions
var isTest*:bool = false

# Forward declaration processMagic
proc processMagic(self: Wox, query: string)

proc register*(self: Wox, name: string, prc: RpcProc) =
  ## Register proc as name
  ##
  ## .. code-block:: Nim
  ##    proc query(wp: Wox, params: varargs[string]) =
  ##      # code
  ##    wp.register("query", query)
  procs[name] = prc

proc call*(self: Wox, name: string, params: varargs[string]) =
  ## Call proc by it's name
  procs[name](self, params)

proc run*(self: Wox, default = "") =
  ## Parse JsonRPC from Wox and call method with params
  ##
  ## .. code-block:: Nim
  ##    wp.run()
  let
    rpcRequest = if default != "": parseJson(default) else: parseJson(paramStr(1))
    requestMethod = rpcRequest["method"].str
    requestParams = rpcRequest["parameters"]

  var params: seq[string] = @[]

  for param in requestParams:
    case param.kind
    of JString:
      params.add(param.getStr)
    of JInt:
      params.add($param.getInt)
    of JFloat:
      params.add($param.getFloat)
    of JBool:
      params.add($param.getBool)
    else:
      params.add($param)

  # if query starts with "plugin:" start process magic actions else call given method
  let query = strutils.strip(params[0])
  if query.startsWith("plugin:"):
    processMagic(self, query)
  else:
    call(self, requestMethod, params)

method add*(self: Wox,
            title,
            sub = "",
            icon = "",
            `method` = "",
            params = "",
            hide: bool = true) {.base.} =
  ## Add item to the return list
  ##
  ## .. code-block:: Nim
  ##    wp.add("Github", "How people build software", "Images\\gh.png",
  ##           "openUrl", "https://github.com/", false)
  self.data.result.add(
    Item(
      Title: title,
      SubTitle: sub,
      IcoPath: icon,
      JsonRPCAction: Action(
        `method`: `method`,
        parameters: @[params],
        dontHideAfterAction: hide
      )
    )
  )

method insert*(self: Wox,
            title,
            sub = "",
            icon = "",
            `method` = "",
            params = "",
            hide: bool = true,
            pos: int = 0) {.base.} =
  ## Insert item at pos to the return list
  ##
  ## .. code-block:: Nim
  ##    wp.insert("Github", "How people build software", "Images\\gh.png",
  ##              "openUrl", "https://github.com/", false, 0)
  self.data.result.insert(
    Item(
      Title: title,
      SubTitle: sub,
      IcoPath: icon,
      JsonRPCAction: Action(
        `method`: `method`,
        parameters: @[params],
        dontHideAfterAction: hide
      )
    ),
    pos
  )

method results*(self: Wox;): string {.base.} =
  ## Return all results
  ##
  ## .. code-block:: Nim
  ##    wp.results()
  # return unidecode($$self.data)
  # return convert($$self.data, "windows-1251", "UTF-8")
  return "\uFEFF" & $$self.data

proc getPluginJson(): JsonNode =
  # load plugin.json
  return json.parseFile(joinPath([getAppDir(), "plugin.json"]))

proc getPluginName(): string =
  # Get name field from plugin.json
  return getPluginJson()["Name"].str

proc getPluginId(): string =
  # Get id field from plugin.json
  return getPluginJson()["ID"].str

proc getSettingsDir(): string =
  # Return settings dir path and create it if not exists
  let settingsDirName = join([getPluginName(), getPluginId()], "-")
  let settingsDir = joinPath([getEnv("APPDATA"), "Wox\\Settings\\Plugins", settingsDirName])
  createDir(settingsDir)
  return settingsDir

proc getCacheDir(): string =
  # Return cache dir path and create it if not exists
  let cacheDirName = join([getPluginName(), getPluginId()], "-")
  let cacheDir = joinPath([getEnv("APPDATA"), "Wox\\Cache", cacheDirName])
  createDir(cacheDir)
  return cacheDir

proc getPluginIcon(): string =
  # Get icon field from plugin.json
  return getPluginJson()["IcoPath"].str

proc getInfoIcon(): string =
  return joinPath([getAppDir(), "Images\\info.png"])

proc getDeleteIcon(): string =
  return joinPath([getAppDir(), "Images\\delete.png"])

# Generate info & delete icons
proc generateIcons() =
  createDir(getAppDir() & "\\Images")

  if not fileExists(getInfoIcon()):
    writeFile(getInfoIcon(), iconInfo.decode)

  if not fileExists(getDeleteIcon()):
    writeFile(getDeleteIcon(), iconDelete.decode)

proc getPluginInfo(): PluginInfo =
  # Parse and load plugin.json
  let pluginJson = getPluginJson()
  var keywords: seq[string] = @[]

  if hasKey(pluginJson, "ActionKeyword"):
    keywords.add(pluginJson["ActionKeyword"].str)
  elif hasKey(pluginJson, "ActionKeywords"):
    for item in pluginJson["ActionKeywords"]:
      keywords.add(item.str)

  PluginInfo(
    id: pluginJson["ID"].str,
    name: pluginJson["Name"].str,
    keyword: keywords,
    desc: pluginJson["Description"].str,
    author: pluginJson["Author"].str,
    version: pluginJson["Version"].str,
    site: pluginJson["Website"].str,
    icon: pluginJson["IcoPath"].str,
    file: pluginJson["ExecuteFileName"].str,
  )

proc loadSettings(): JsonNode =
  # Load settings from settings.json
  let settingsFile = joinPath([getSettingsDir(), "settings.json"])
  if existsFile(settingsFile):
    return parseFile(settingsFile)
  else:
    return newJObject()

method saveSettings*(self: Wox) {.base.} =
  ## Save settings to settings.json
  ##
  ## .. code-block:: Nim
  ##    wp.saveSettings()
  let settingsFile = joinPath([getSettingsDir(), "settings.json"])
  writeFile(settingsFile, self.settings.pretty)

proc cacheFile(name: string): string =
  # Path to cache file
  return joinPath([getCacheDir(), name])

proc cacheAge(name: string): float =
  # Return age of cache in secs or 0 if cache not exist
  let cacheFile = cacheFile("$1.json" % name)
  if not fileExists(cacheFile):
    return 0
  return epochTime() - toUnixFloat(getLastModificationTime(cacheFile))

proc isCacheOld*(name: string; maxAge: float = 0): bool =
  ## Сhecks the cache has expired or not
  ##
  ## .. code-block:: Nim
  ##    if isCacheOld("cache_file", 60):
  ##      # code
  let age = cacheAge(name)
  if age == 0:
      return true
  return age > maxAge

method loadCache*(self: Wox; name: string): JsonNode {.base.} =
  ## Load cached data from file
  ##
  ## .. code-block:: Nim
  ##    wp.loadCache("cache_file")
  let cacheFile = cacheFile("$1.json" % name)
  return parseFile(cacheFile)

method saveCache*(self: Wox; name: string; data: JsonNode) {.base.} =
  ## Save cache to file
  ##
  ## .. code-block:: Nim
  ##    wp.saveCache("cache_file")
  let cacheFile = cacheFile("$1.json" % name)
  writeFile(cacheFile, data.pretty)

method sort*(self: Wox,
           query: string,
           sortBy = byTitleSub,
           minScore: float = 0.0,
           maxResults = 0) {.base.} =
  ## Fuzzy sorting the results, default sorted by title and subtitle
  ##
  ## .. code-block:: Nim
  ##    wp.sort(query, minScore = 10, maxResults = 10, sortBy = byTitle)
  var query = query.toLower

  proc score(value: string): float =
    ## Calculate score

    var score = 0.0

    if not (toHashSet(query) <= toHashSet(value.toLower)):
      return score

    ## item starts with query
    if value.toLower.startsWith(query):
      score = 100.0 - (value.len / query.len)
      return score

    # capitalized chars e.g. gh = GitHub
    var initials = ""
    for c in value.runes:
      if c.isUpper or c.isDigit: initials = initials & $c
    if initials.toLower.startsWith(query):
      score = 100.0 - (initials.len / query.len)
      return score

    ## query one of the atoms in item, one two three = oth
    var atoms = value.split(peg"[^a-zA-Z0-9]+")
    for k, s in atoms:
      atoms[k] = s.toLower

    initials = ""
    for s in atoms:
      initials = initials & s[0]

    # if query in atoms e.g. atoms == @["the", "last", word"] and query == "word"
    if query in atoms:
      score = 100.0 - (value.len / query.len)
      return score

    ## one two three == oth
    if initials.startsWith(query):
      score = 100.0 - (initials.len / query.len)
      return score
    elif query in initials:
      score = 95.0 - (initials.len / query.len)
      return score

    ## substring
    if query in value.toLower:
      score = 90.0 - (value.len / query.len)
      return score

    return score

  proc cmpSort(x, y: Item): int =
    var text: array[0..1, string]
    case sortBy:
      of byTitle:
        text = [x.Title, y.Title]
      of bySub:
        text = [x.SubTitle, y.SubTitle]
      of byTitleSub:
        text = [x.Title & " " & x.SubTitle, y.Title & " " & y.SubTitle]
    cmp(score(text[0]), score(text[1]))

  proc cmpFilter(x: Item): bool =
    var text: string
    case sortBy:
      of byTitle:
        text = x.Title
      of bySub:
        text = x.SubTitle
      of byTitleSub:
        text = x.Title & " " & x.SubTitle
    return score(text) > minScore

  self.data.result.sort(cmpSort, SortOrder.Descending)

  if minScore != 0:
    self.data.result = filter(self.data.result, cmpFilter)
  if maxResults != 0 and self.data.result.len > maxResults-1:
    self.data.result = self.data.result[0..maxResults-1]

# Processing magic actions
proc processMagic(self: Wox, query: string) =
  let
    id = query[prefix.len..^1]

  # If the action exists - show it
  for id, action in magicActions.pairs:
    let icon = if (action.actionType == actionNegative): "Images\\delete.png" else: "Images\\info.png"
    self.add(title = action.desc, icon = icon, `method` = action.run)
  if id != "":
    self.sort(id, minScore = 10.0, sortBy = byTitle)
  if self.data.result.len == 0:
    self.add("No Results", "", "Images\\info.png", "", "", true)
  if not isTest:
    echo self.results

# Open help link
proc openHelp(self: Wox, params: varargs[string]) =
  openDefaultBrowser(self.help)

# Open plugin dir
proc openData(self: Wox, params: varargs[string]) =
  discard execShellCmd("start \"\" " & "\"" & self.pluginDir & "\"")

# Open plugin cache dir
proc openCache(self: Wox, params: varargs[string]) =
  discard execShellCmd("start \"\" " & "\"" & self.cacheDir & "\"")

# Open plugin settings dir
proc openSettings(self: Wox, params: varargs[string]) =
  discard execShellCmd("start \"\" " & "\"" & self.settingsDir & "\"")

# TODO: (we need logging?)
# proc openLog(self: Wox, params: varargs[string]) =
#   echo "open log"

# Delete all plugin cache
proc deleteCache(self: Wox, params: varargs[string]) =
  removeDir(self.cacheDir)

# Delete all plugin settings
proc deleteSettings(self: Wox, params: varargs[string]) =
  removeDir(self.settingsDir)


# Add/register magic actions
proc addMagic(self: Wox, id: string, desc: string, run: string, `proc`: RpcProc, actionType: MagicActionType) =
  magicActions[id] = MagicAction(
    id: id,
    desc: desc,
    run: run,
    actionType: actionType
  )
  self.register(run, `proc`)

proc newWox*(help: string = ""): Wox =
  ## Create a Wox object
  ##
  ## .. code-block:: Nim
  ##    var wp = newWox()
  let tmpPluginInfo = getPluginInfo()

  new(result)

  result.data = Result(result: @[])
  result.pluginDir = getAppDir()
  result.plugin = tmpPluginInfo
  result.settingsDir = getSettingsDir()
  result.cacheDir = getCacheDir()
  result.settings = loadSettings()
  result.help = help

  # Generate icons if not exists
  generateIcons()

  # Register openHelp proc only if help link not empty
  if help != "":
    result.addMagic("help", "Open plugin help URL in browser", "openHelp", openHelp, actionPositive)
  # TODO: (we need logging?)
  # result.addMagic("log", "Open plugin's log file", "openLog", openLog)

  # Register all other magic actions
  result.addMagic("cache", "Open plugin's cache dir", "openCache", openCache, actionPositive)
  result.addMagic("settings", "Open plugin's settings dir", "openSettings", openSettings, actionPositive)
  result.addMagic("delcache", "Delete plugin's cached data", "deleteCache", deleteCache, actionNegative)
  result.addMagic("delsettings", "Delete plugin's settings", "deleteSettings", deleteSettings, actionNegative)
  result.addMagic("data", "Open plugin's dir", "openData", openData, actionPositive)

