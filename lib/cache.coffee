moment = require "moment"
NodeCache = require "node-cache"
q = require "q"

class Cache extends NodeCache
  get: ->
    defer = q.defer()
    key = arguments[0]

    start = moment()
    super arguments..., (err, data) ->
      if err? or not data?
        console.log "non-cached", key, moment().diff start
      else
        console.log "cached", key, moment().diff start
      defer.reject err if err? or not data?
      defer.resolve data

    defer.promise

module.exports = new Cache { stdTTL: 60, checkperiod: 120 }
