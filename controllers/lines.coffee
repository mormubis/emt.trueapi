cache = require "../lib/cache"
express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
geolib = require "geolib"
q = require "q"
_ = require "underscore"

getLines = (line, extended) ->
  defer = q.defer()
  key = line or "all"
  key += ":extended" if extended

  cache.get key
  .catch ->
    EMT.lines line
    .then (lines) ->
      if extended
        return EMT.stops()
        .then (stops) ->
          for stop in stops
            for line in stop.lines
              if lines[parseInt line.number]
                lines[parseInt line.number].stops.push
                  name: stop.name
                  latitude: stop.latitude
                  longitude: stop.longitude

          lines
      lines
    # save cache
    .then (lines) ->
      cache.set key, lines, 2 * 60 * 60
      lines
  # cleaning
  .then (lines) ->
    defer.resolve _.filter lines
  .catch defer.reject

  defer.promise

module.exports = new express.Router()
.get "/:id?", (req, res) ->
  getLines req.params.id, (req.query.latlng || req.query.nwlatlng)?
  # coordinates filter
  .then filter req.query.nwlatlng, (line) ->
    nwlatlng = req.query.nwlatlng.split ","
    selatlng = req.query.selatlng.split ","
    coordinates = [
      {latitude: nwlatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: selatlng[1]}
      {latitude: nwlatlng[0], longitude: selatlng[1]}
    ]
    isIn = false

    for stop in line.stops
      if geolib.isPointInside stop, coordinates
        isIn = true
        break

    isIn
  # distance filter
  .then filter req.query.latlng, (line) ->
    isIn = false
    latlng = req.query.latlng.split ","
    needle = {latitude: latlng[0], longitude: latlng[1]}
    req.query.radius?= 250

    for stop in line.stops
      if (geolib.getDistance stop, needle) <= req.query.radius
        isIn = true
        break

    isIn
  # name filter
  .then filter req.query.name, (line) ->
    (new RegExp req.query.name, "i").test line.sources
  # formatting and sending
  .then (lines) ->
    lines = for line in lines
      delete line.stops
      line

    res.json lines
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/stops", (req, res) ->
  getLines req.params.id, true
  # selecting line
  .then (lines) ->
    return lines[0].stops
  # name filter
  .then filter req.query.name, (stop) ->
    (new RegExp req.query.name, "i").test stop.name
  # latlng filter
#  .then filter req.query.latlng, (needle, stop) ->
#    latlng = req.query.latlng
#    (geolib.getDistance stop, {latitude: needle[0], longitude: needle[1]}) <= req.query.radius
  # formatting and sending
  .then (stops) ->
    res.json stops
  .catch ->
    console.log arguments
    res.sendStatus 500
