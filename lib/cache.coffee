NodeCache = require "node-cache"
q = require "q"

class Cache extends NodeCache
  get: ->
    defer = q.defer()

    super arguments..., (err, data) ->
      defer.reject err if err? or not data?
      defer.resolve data

    defer.promise

module.exports = new Cache { stdTTL: 60, checkperiod: 120 }
