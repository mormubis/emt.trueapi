filter = require "./filter"
geolib = require "geolib"

module.exports = (origin, radius, getter) ->
  origin = origin.split ","
  origin = {latitude:  origin[0], longitude: origin[1]}

  filter origin || radius, (value) ->
    (geolib.getDistance value, origin) <= radius
