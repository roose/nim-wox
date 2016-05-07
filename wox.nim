import json, strutils, sequtils, marshal

"""
Helper library for Wox plugin authors
"""

type
  Action = object
    """Wox JsonRPCAction object"""
    `method`: string
    parameters: string
    dontHideAfterAction: bool

  WoxItem = object
    """Wox item object"""
    Title: string
    SubTitle: string
    IcoPath: string
    JsonRPCAction: Action

  WoxResult = object
    """Wox results object"""
    `result`: seq[WoxItem]

proc newResult*(): WoxResult =
  """
  Init WoxResult
  """

  return WoxResult(result: @[])

proc addItem*(self: var WoxResult, title, sub, icon, `method`, params: string, hide: bool = true) =
  """
  Add item to the return list

  :param str title: item title
  :param str sub: item subtitle
  :param str icon: path to item icon
  :param str method: a function called when an item is selected
  :param list params: parameters for callable function
  :param str hide: hide Wox after select item or not
  """

  self.result.add(WoxItem(
                    Title: title,
                    SubTitle: sub,
                    IcoPath: icon,
                    JsonRPCAction: Action(
                      `method`: `method`,
                      parameters: params,
                      dontHideAfterAction: hide
                    )
                 ))

proc results*(self: var WoxResult): string =
  """
  Return results with all items
  """

  return $$self

proc filter*(self: var WoxResult, items: any, key: proc): seq[tuple[text: string, score: float]] =
  """
  Search filter

  :param iterable items: any iterable items to search
  :param proc key: function to create a string for the search query
  :return seq: sequence of filtred items
  """

  result = @[]
  let query = "color"

  for item in items:
    var score = 0.0
    var value = key(item)
    if value == "": continue
    if value.toLower.startsWith(query):
      score = 100.0 - (value.len / query.len)
    elif query in value.toLower:
      score = 80.0 - (value.len / query.len)
    if score > 0.0:
      result.add(($item, score))

  result.sort(proc(x, y: tuple) :int =
    cmp(x.score, y.score), SortOrder.Descending)
  return result
