cache = require "../lib/cache"
express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
geolib = require "geolib"
q = require "q"
querystring = require "querystring"
_ = require "underscore"

getLines = (line, extended) ->
  key = "lines:"
  key += if line? then line else "all"
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
    _.filter lines

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
  # common errors
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/nodes", (req, res) ->
  EMT.nodes req.params.id
  # coordinates filter
  .then filter req.query.nwlatlng, (node) ->
    nwlatlng = req.query.nwlatlng.split ","
    selatlng = req.query.selatlng.split ","
    coordinates = [
      {latitude: nwlatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: nwlatlng[1]}
      {latitude: selatlng[0], longitude: selatlng[1]}
      {latitude: nwlatlng[0], longitude: selatlng[1]}
    ]

    geolib.isPointInside node, coordinates
  # sending
  .then (nodes) ->
    res.json nodes
  # common errors
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/stops", (req, res) ->
  query = req.query
  query?.line = req.params.id

  res.redirect "/stops?#{querystring.stringify query}"
