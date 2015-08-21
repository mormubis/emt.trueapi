app = require "./app"
bodyParser = require "body-parser"

# setup
app.use bodyParser.urlencoded extended: true

app.locals.EMT =
  client: "WEB.SERV.adrian.delarosab@gmail.com"
  password: "913F9917-AF5D-4E08-8DFF-64FE5C998864"
  url: "https://openbus.emtmadrid.es:9443/emt-proxy-server/last"

# content
app
.use "/lines", require "./controllers/lines"
.use "/stops", require "./controllers/stops"

# fallback
app
.all "/", (req, res) ->
  res.redirect "http://docs.emt1.apiary.io/"
.all "*", (req, res) ->
  res.sendStatus 404

# server
app.listen 3000
