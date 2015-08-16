_ = require "underscore"

module.exports = (needle, predicate) ->
  (collection) ->
    collection = _.filter collection, predicate if needle?

    collection
