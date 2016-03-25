app = require "./app"
bodyParser = require "body-parser"
morgan = require "morgan"
ua = require "universal-analytics"

# setup
app.use bodyParser.urlencoded extended: true

app.locals.EMT =
  client: "WEB.SERV.adrian.delarosab@gmail.com"
  password: "913F9917-AF5D-4E08-8DFF-64FE5C998864"
  url: "https://openbus.emtmadrid.es:9443/emt-proxy-server/last"

# content
app
.use morgan "combined"
#.use ua.middleware "UA-66458518-2", {cookieName: '_ga'}
.use "/lines", require "./controllers/lines"
.use "/stops", require "./controllers/stops"

# fallback
app
.all "/", (req, res) ->
  res.json collection:
    href: "http://emt.trueapi.com/"
    links: [
      {href: "http://emt.trueapi.com/lines", name: "Line resource", rel: "search"}
      {href: "http://emt.trueapi.com/stops", name: "Stop resource", rel: "search"}
      {href: "http://docs.emt1.apiary.io/", name: "Documentation", rel: "help"}
    ]
.all "*", (req, res) ->
  res.sendStatus 404

# server
app.listen 3000
