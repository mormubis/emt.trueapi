filter = require "./filter"
geolib = require "geolib"

module.exports = (origin, radius = 250) ->
  origin = origin.split ","
  origin = {latitude:  origin[0], longitude: origin[1]}

  filter origin and radius, (value) ->
    (geolib.getDistance value, origin) <= radius
