filter = require "./filter"
geolib = require "geolib"

module.exports = (nelatlng, swlatlng, getter) ->
  if nelatlng
    nelatlng = nelatlng.split ","
    swlatlng = swlatlng.split ","

    coordinates = [
      {latitude: nelatlng[0], longitude: swlatlng[1]}
      {latitude: nelatlng[0], longitude: nelatlng[1]}
      {latitude: swlatlng[0], longitude: nelatlng[1]}
      {latitude: swlatlng[0], longitude: swlatlng[1]}
    ]

  filter nelatlng || swlatlng, (value) ->
    geolib.isPointInside value, coordinates
