cache = require "../lib/cache"
express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
querystring = require "querystring"
radiusFilter = require "../lib/radius.filter"
squareFilter = require "../lib/square.filter"
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
        return EMT.stops line
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
  getLines req.params.id, (req.query.latlng || req.query.nelatlng)?
  # coordinates filter
  .then filter req.query.nelatlng, (line) ->
    matcher = squareFilter req.query.nelatlng, req.query.swlatlng

    (matcher line.stops).length > 0
  # distance filter
  .then filter req.query.latlng, (line) ->
    matcher = radiusFilter req.query.latlng, req.query.radius

    (matcher line.stops).length > 0
  # name filter
  .then filter req.query.name, (line) ->
    (new RegExp req.query.name, "i").test line.sources
  # formatting and sending
  .then (lines) ->
    lines = for line in lines
      delete line.stops
      line

    res.json collection:
      items: for data in lines
        data: data
        href: "http://emt.trueapi.com/lines/#{data.number}"
        link: [
          {
            href: "http://emt.trueapi.com/lines/#{data.number}/nodes"
            name: "Vertex of the line"
            rel: "search"
          }
          {
            href: "http://emt.trueapi.com/lines/#{data.number}/stops",
            name: "Stops of the line"
            rel: "search"
          }
          {
            href: "http://emt.trueapi.com/lines/#{data.number}/timetable",
            name: "Timetable of the line"
            rel: "search"
          }
        ]
      queries: [
        href: "http://emt.trueapi.com/lines"
        data: [
          {name: "latlng", value: ""}
          {name: "name", value: ""}
          {name: "nelatlng", value: ""}
          {name: "swlatlng", value: ""}
          {name: "radius", value: 250}
        ]
      ]
  # common errors
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/nodes", (req, res) ->
  EMT.nodes req.params.id
  # coordinates filter
  .then squareFilter req.query.nelatlng, req.query.swlatlng
  # sending
  .then (nodes) ->
    if nodes.length then res.json nodes else res.sendStatus 404
  # common errors
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/stops", (req, res) ->
  query = req.query
  query?.line = req.params.id

  res.redirect "/stops?#{querystring.stringify query}"
