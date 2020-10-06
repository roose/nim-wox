import os, osproc, json, unittest, typetraits, terminal, ../src/wox

suite "testing wox.nim":
  setup:
    let
      pluginFile = joinPath(getAppDir(), "data\\plugin.json")
      pluginPath = joinPath(getAppDir(), "plugin.json")
      appdata = getEnv("APPDATA")
      env = (
        name: "Wox.nim test plugin",
        id: "574f582e4e494d2e544553542e504c55",
        pluginDir: getAppDir(),
        cacheDir: joinPath(appdata, "Wox\\Cache\\Plugins\\Wox.nim test plugin-574f582e4e494d2e544553542e504c55"),
        settingsDir: joinPath(appdata, "Wox\\Settings\\Plugins\\Wox.nim test plugin-574f582e4e494d2e544553542e504c55")
      )
      items = @["Test Item One", "test item two",
                "TwoExtraSpecialTest", "this-is-a-test",
                "the extra special trials", "not the extra special trials",
                "intestinal fortitude", "the splits", "nomatch"]

    copyFile(pluginFile, pluginPath)
    var wp = newWox()

    proc test(w: Wox, params: varargs[string]) = discard

  teardown:
    removeFile(pluginPath)

  test "can compile wox.nim":
    check execCmdEx("nim c src/wox").exitCode == QuitSuccess

  test "wox environmental variables":
    check wp.pluginDir == getAppDir()
    check wp.settingsDir == env.settingsDir
    check wp.plugin.name == env.name
    check wp.plugin.id == env.id

  test "load/save cache":
    let data = parseJson("""{"key1": "value1"}""")
    wp.saveCache("test", data)
    let d = wp.loadCache("test")
    check data == d

  test "load/save settings":
    wp.settings["test"] = %"settings"
    wp.settings["test_int"] = %1
    wp.saveSettings()
    check wp.settings["test"].getStr == "settings"
    check wp.settings["test_int"].getInt == 1

  test "adding item":
    wp.add("title",
           "subtitle",
           "icon",
           "method",
           "params",
           true
      )
    check len(wp.data.result) == 1
    let item = wp.data.result[0]
    check item.Title == "title"
    check item.SubTitle == "subtitle"
    check item.IcoPath == "icon"
    check item.JsonRPCAction.`method` == "method"
    check item.JsonRPCAction.parameters[0] == "params"
    check item.JsonRPCAction.dontHideAfterAction == true


  test "sorting items":
    for item in items:
      wp.add(item)
    wp.sort("test")
    check len(wp.data.result) == 9
    check wp.data.result[0].Title == "TwoExtraSpecialTest"

  test "sorting order":
    for item in items:
      wp.add(item)
    wp.sort("test", sortBy = byTitle)
    wp.sort("test", sortBy = bySub)
    wp.sort("test", sortBy = byTitleSub)

  test "filter max result":
    for item in items:
      wp.add(item)
    wp.sort("test", maxResults = 5)
    check len(wp.data.result) == 5

  test "filter min score":
    for item in items:
      wp.add(item)
    wp.sort("test", minScore = 10)
    check len(wp.data.result) == 7

  test "register proc":
    wp.register("test", test)

  test "call proc":
    wp.call("test", "single param")
    wp.call("test", "params 1", "params 2")
    wp.call("test", ["array param 1", "array param 2"])
    wp.call("test", @["seq param 1", "seq param 2"])

  test "run proc":
    let rpc = """{"method": "test", "parameters": ["test param 1", "test param 2"]}"""
    wp.run(rpc)
