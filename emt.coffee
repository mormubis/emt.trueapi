app = require "./app"
moment = require "moment"
q = require "q"
request = require "./lib/request"
_ = require "underscore"

EMT = app.locals.EMT
moment.locale "es"

module.exports =
  lines: (line) ->
    defer = q.defer()

    data = {SelectDate: moment().format "L" }
    data.Lines = line if line?

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
    .then defer.resolve
    .catch defer.reject
    # throwing errors from this point
    .done()

    defer.promise

  sign: (data) ->
    data?.idClient = EMT.client
    data?.passKey = EMT.password

    data

  stops: ->
    defer = q.defer()

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
      stops = for item in response
        name: item.name
        lines: for line in item.lines
          line = line.split "/"
          isForward: line[1] is "1"
          number: line[0]
        latitude: item.latitude
        longitude: item.longitude

      stops
    .then defer.resolve
    .catch defer.reject
    # throwing errors from this point
    .done()

    defer.promise
