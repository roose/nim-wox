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

import tables, os, algorithm, strutils, sequtils, sets, unicode
import json, marshal, tables, pegs, times

from unicodeplus import isDigit

type
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

  RpcProc* = proc (self: Wox, params: varargs[string])

  SortBy* = enum
    ## Sort by title or subtitle or title and subtitle
    byTitle, bySub, byTitleSub

# name, proc table for call proc
var procs: Table[string, RpcProc] = initTable[string, RpcProc]()

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
    # params.add(param.getStr)
    # params.add($param)
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
  return $$self.data

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

proc newWox*(): Wox =
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
