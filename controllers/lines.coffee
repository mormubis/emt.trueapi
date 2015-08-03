Cache = require "../lib/cache"
express = require "express"
EMT = require "../emt"
q = require "q"
_ = require "underscore"
nameFilter = require "../filters/name"

cache = new Cache { stdTTL: 60, checkperiod: 120 }

getLinesInformation = (line, extended) ->
  defer = q.defer()
  key = line or "all"
  key += ":extended" if extended

  cache.get key
  .then defer.resolve
  .catch ->
    EMT.lines(line)
    .get "resultValues"
    .then (response) ->
      response ?= []
      # FIXME Check http://opendata.emtmadrid.es/Foros.aspx?forumid=40&threadid=418
      unless _.isArray response
        response = [response]

      lines = []

      for item in response
        lines[parseInt item.line] =
          name: item.label
          number: item.line
          sources: [item.nameA, item.nameB]
          stops: []

      return lines
    .then (lines) ->
      if extended
        return EMT.stops()
        .get "resultValues"
        .then (response) ->
          stops = for stop in response
            name: stop.name
            lines: (_.map stop.lines, (value) -> (value.split "/").shift())
            latitude: stop.latitude
            longitude: stop.longitude

          for stop in stops
            for line in stop.lines
              if lines[parseInt line]
                lines[parseInt line].stops.push
                  name: stop.name
                  latitude: stop.latitude
                  longitude: stop.longitude

          return lines

      return lines
    .then (lines) ->
      lines = _.filter lines
      cache.set key, lines, 2 * 60 * 60
      defer.resolve lines
  .catch defer.reject

  defer.promise

toRadians = (coordinate) ->
  coordinate * Math.PI / 180

getDistance = (origin, target) ->
  originLatitudeRad = toRadians origin.latitude
  targetLatitudeRad = toRadians target.latitude

  (Math.acos (Math.sin originLatitudeRad) * (Math.sin targetLatitudeRad) + (Math.cos originLatitudeRad) * (Math.cos targetLatitudeRad) * (Math.cos toRadians origin.longitude - target.longitude)) * 180 / Math.PI * 60 * 1.1515 * 1.609344 * 1000

module.exports = new express.Router()
.get "/:id?", (req, res) ->
  getLinesInformation req.params.id, req.query.latlng
  # name filter
#  .then nameFilter "nameFilter", req.query.name
  # latlng filter
  .then (lines) ->
    if req.query.latlng?
      req.query.radius ?= 250

      filter = []
      latlng = req.query.latlng.split ","

      for line in lines
        for stop in line.stops
          if (getDistance stop, {latitude: latlng[0], longitude: latlng[1]}) <= req.query.radius
            filter.push line
            break

      lines = filter

    return lines
  # formatting
  .then (lines) ->
    lines = for line in lines
      delete line.stops
      line

    res.json lines
  .catch ->
    console.log arguments
    res.sendStatus 500
.get "/:id/stops", (req, res) ->
  getLinesInformation req.params.id, true
  # selecting line
  .then (lines) ->
    return lines[0].stops
  # name filter
  .then (stops) ->
    if req.query.name?
      filter = []
      regexp = new RegExp req.query.name, "i"

      for stop in stops
        if regexp.test stop.name
          filter.push stop
          break

      stops = filter

    return stops
  .then (stops) ->
    if req.query.latlng?
      req.query.radius ?= 250

      filter = []
      latlng = req.query.latlng.split ","

      for stop in stops
        if (getDistance stop, {latitude: latlng[0], longitude: latlng[1]}) <= req.query.radius
          filter.push stop
          break

      stops = filter

    return stops
  # formatting
  .then (stops) ->
    res.json stops


