app = require "./app"
cache = require "./lib/cache"
moment = require "moment"
q = require "q"
request = require "./lib/request"
_ = require "underscore"

EMT = app.locals.EMT
moment.locale "es"

module.exports =
  arrives: (stop) ->
    key = "emt:arrives"

    data = {}
    if stop?
      data.idStop = stop
      key += ":#{stop}"

    cache.get key
    # non-cached
    .catch =>
      request
        expiration: 3
        form: @sign data
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
      # caching
      .then (arrives) ->
        cache.set key, arrives, 5
        arrives

  lines: (line) ->
    key = "emt:lines"

    data = {SelectDate: moment().format "L"}
    if line?
      data.Lines = line
      key += ":#{line}"

    cache.get key
    # non-cached
    .catch =>
      request
        expiration: 6 * 60 * 60
        form: @sign data
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
      # caching
      .then (lines) ->
        cache.set key, lines, 6 * 60 * 60
        lines

  nodes: (line) ->
    key = "emt:nodes"

    data = {}
    if line?
      data.Lines = line
      key += ":#{line}"

    cache.get key
    # non-cached
    .catch =>
      request
        expiration: 6 * 60 * 60
        form: @sign data
        json: true
        method: "POST"
        url: "#{EMT.url}/geo/GetRouteLinesRoute.php"
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
      # caching
      .then (nodes) ->
        cache.set key, nodes, 6 * 60 * 60
        nodes

  sign: (data) ->
    data?.idClient = EMT.client
    data?.passKey = EMT.password

    data

  stops: ->
    key = "emt:stops"

    cache.get key
    .then (stops) ->
      stops
    # non-cached
    .catch =>
      request
        expiration: 6 * 60 * 60
        form: @sign {}
        json: true
        method: "POST"
        url: "#{EMT.url}/bus/GetNodesLines.php"
        strictSSL: false
      # get result attribute
      .get "resultValues"
      # formatting
      .then (response) ->
        for item in response
          id: item.node
          name: item.name
          lines: for line in item.lines
            line = line.split "/"
            isForward: line[1] is "1"
            number: line[0]
          latitude: item.latitude
          longitude: item.longitude
      # caching
      .then (stops) ->
        cache.set key, stops, 6 * 60 * 60
        stops
