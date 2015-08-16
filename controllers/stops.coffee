express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
_ = require "underscore"

module.exports = new express.Router()
.get "/", (req, res) ->
  EMT.stops()
  # coordinates filter
  .then filter req.query.nwlatlng, (stop) ->
    nwlatlng = req.query.nwlatlng.split ","
    selatlng = req.query.selatlng.split ","
    coordinates = [
      {latitude: nwlatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: selatlng[1]}
      {latitude: nwlatlng[0], longitude: selatlng[1]}
    ]

    geolib.isPointInside stop, coordinates
  # distance filter
  .then filter req.query.latlng, (stop) ->
    latlng = req.query.latlng.split ","
    needle = {latitude: latlng[0], longitude: latlng[1]}

    (geolib.getDistance stop, needle) <= req.query.radius
  # line filter
  .then filter req.query.line, (stop) ->
    (_.findWhere stop.lines, {number: req.query.line})?
  # name filter
  .then filter req.query.name, (stop) ->
    (new RegExp req.query.name, "i").test stop.name
