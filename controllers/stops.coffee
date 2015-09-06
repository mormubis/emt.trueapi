express = require "express"
EMT = require "../emt"
filter = require "../lib/filter"
radiusFilter = require "../lib/radius.filter"
squareFilter = require "../lib/square.filter"

module.exports = new express.Router()
.get "/:id?", (req, res) ->
  EMT.stops req.query.line
  # coordinates filter
  .then squareFilter req.query.nelatlng, req.query.swlatlng
  # distance filter
  .then radiusFilter req.query.latlng, req.query.radius
  # id filter
  .then filter req.params.id, (stop) ->
    stop.id is req.params.id
  # name filter
  .then filter req.query.name, (stop) ->
    (new RegExp req.query.name, "i").test stop.name
  # sending
  .then (stops) ->
    res.json stops
  # common errors
  .catch (e) ->
    console.log e
    res.sendStatus 500
.get "/:id/arrives", (req, res) ->
  EMT.arrives req.params.id
  .then (arrives) ->
    res.json arrives
  .catch (e) ->
    console.log e
    res.sendStatus 500
