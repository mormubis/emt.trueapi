app = require "./app"
cache = require "./lib/cache"
moment = require "moment"
q = require "q"
request = require "./lib/request"
_ = require "underscore"

EMT = app.locals.EMT
moment.locale "es"

sign = (data) ->
  data?.idClient = EMT.client
  data?.passKey = EMT.password

  data

get = (key, data, ttl, fallback) ->
  isCached = false

  cache.get key
  # isCached?
  .then (value) ->
    isCached = true
    value
  # non-cached
  .catch fallback
  # caching
  .then (value) ->
    unless isCached
      cache.set key, value, ttl
    value

module.exports =
  arrives: (stop) ->
    key = "emt:arrives"

    data = {}
    if stop?
      data.idStop = stop
      key += ":#{stop}"

    get key, data, 2, ->
      request
        expiration: 1
        form: sign data
        json: true
        method: "POST"
        url: "#{EMT.url}/geo/GetArriveStop.php"
        strictSSL: false
      # get result attribute
      .get "arrives"
      # formatting
      .then (response) ->
        for item in response
          line: item.lineId
          timeLeft: if item.busTimeLeft isnt 999999 then item.busTimeLeft else "+20min"
      # remove duplicates
      .then (arrives) ->
        _.uniq arrives, (value) -> JSON.stringify value

  lines: (line, date = moment().format "L") ->
    key = "emt:lines"

    data = {SelectDate: date}
    if line?
      data.Lines = line
      key += ":#{line}"

    get key, data, 6 * 60 * 60, ->
      request
        expiration: 3 * 60 * 60
        form: sign data
        json: true
        method: "POST"
        url: "#{EMT.url}/bus/GetListLines.php"
        strictSSL: false
      # get result attribute
      .get "resultValues"
      # fix because opendata.emtmadrid.es :)
      .then (response) ->
        response ?= []
        # FIXME Check http://opendata.emtmadrid.es/Foros.aspx?forumid=40&threadid=418
        unless _.isArray response
          response = [response]

        response
      # formatting
      .then (response) ->
        lines = []

        for item in response
          lines[parseInt item.line] =
            name: item.label
            number: item.line
            sources: [item.nameA, item.nameB]
            stops: []

        lines

  nodes: (line) ->
    key = "emt:nodes"

    data = {}
    if line?
      data.Lines = line
      key += ":#{line}"

    get key, data, 6 * 60 * 60, ->
      request
        expiration: 3 * 60 * 60
        form: sign data
        json: true
        method: "POST"
        url: "#{EMT.url}/bus/GetRouteLinesRoute.php"
        strictSSL: false
      # get result attribute
      .get "resultValues"
      # fix
      .then (response) ->
        response ?= []

        response
      # formatting
      .then (response) ->
        for item in response
          isForward: item.secDetail < 20
          latitude: item.latitude
          longitude: item.longitude

  stops: (line, date = moment().format "L") ->
    key = "emt:stops"

    data = {SelectDate: date}
    if line?
      data.Lines = line
      key += ":#{line}"

    url = EMT.url + if line? then "/bus/GetRouteLines.php" else "/bus/GetNodesLines.php"

    get key, data, 6 * 60 * 60, ->
      request
        expiration: 3 * 60 * 60
        form: sign data
        json: true
        method: "POST"
        url: url
        strictSSL: false
      # get result attribute
      .get "resultValues"
      # formatting
      .then (response) ->
        for item in response
          lines = [{line: item.line, isForward: item.secDetails is 10}]

          if item.lines?
            lines = for line in item.lines
              line = line.split "/"

              isForward: line[1] is "1"
              number: line[0]

          id: item.node
          name: item.name
          lines: lines
          latitude: item.latitude
          longitude: item.longitude

  timetable: (line, date = moment().format "L") ->
    key = "emt:timetable"

    data = {SelectDate: date}
    if line?
      data.Lines = line
      key += ":#{line}"

    get key, data, 6 * 60 * 60, ->
      request
        expiration: 3 * 60 * 60
        form: sign data
        json: true
        method: "POST"
        url: "#{EMT.url}/"
        strictSSL: false
      # get result attribute
      .get "resultValues"
      # formatting
      .then (response) ->




