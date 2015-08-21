express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
geolib = require "geolib"
_ = require "underscore"

module.exports = new express.Router()
.get "/:id?", (req, res) ->
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
    req.query.radius?= 250

    (geolib.getDistance stop, needle) <= req.query.radius
  # line filter
  .then filter req.query.line, (stop) ->
    (_.findWhere stop.lines, {number: req.query.line})?
  # name filter
  .then filter req.query.name, (stop) ->
    (new RegExp req.query.name, "i").test stop.name
  # formatting and sending
  .then (stops) ->
    if req.query.line
      stops = for stop in stops
        delete stop.lines
        stop

    res.json stops
  # id filter
  .then filter req.params.id, (stop) ->
    stop.id is req.params.id
  # common erros
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/arrives", (req, res) ->
  EMT.arrives req.params.id
  # line filter
#  .then filter req.query.line, (arrive) ->
  .then (arrives) ->
    res.json arrives
  .catch (e) ->
    console.log e
    res.sendStatus 500
