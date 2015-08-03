app = require "./app"
moment = require "moment"
q = require "q"
request = require "./lib/request"

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
    .then defer.resolve, defer.reject

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
    .then defer.resolve, defer.reject

    defer.promise
