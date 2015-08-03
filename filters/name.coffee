module.exports = (attribute, needle) ->
  (collection) ->
    unless needle?
      return collection

    filter = []
    needleRegExp = new RegExp needle, "i"

    for value in collection
      if needleRegExp.test value?[attribute]
        filter.push value
        break

    return filter


