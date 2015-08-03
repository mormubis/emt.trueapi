NodeCache = require "node-cache"
q = require "q"

module.exports = class extends NodeCache
  get: ->
    defer = q.defer()

    super arguments..., (err, data) ->
      defer.reject err if err? or not data?
      defer.resolve data

    defer.promise
