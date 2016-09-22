const app = require('../app');
const express = require('express');
const EMT = new (require('../emt'))(
  app.locals.EMT.client,
  app.locals.EMT.password
);
const filter = require('../lib/filter');
const querystring = require('querystring');
const latlng = require('../lib/latlng');
const radius = require('../lib/filter-radius');
const square = require('../lib/filter-square');

module.exports = new express.Router()
  .get(
    '/:id?',
    (request, response) => {
      const regexp = new RegExp(request.query.name, 'i');

      EMT.lines(request.params.id)
        // name filter
        .then(filter(request.query.name, (line) => regexp.test(line.sources)))
        // send
        .then(response.json.bind(response))
        .catch(
          (e) => {
            console.error(e.stack);
            response.sendStatus(500);
          }
        );
    }
  )
  .get(
    '/:id/nodes',
    (request, response) => {
      const nelatlng = latlng(request.query.nelatlng);
      const swlatlng = latlng(request.query.swlatlng);

      EMT.nodes(request.params.id)
        // coordinates filter
        .then(square(nelatlng, swlatlng))
        // send
        .then(response.json.bind(response))
        // error
        .catch(
          (e) => {
            console.error(e);
            response.sendStatus(500);
          }
        );
    }
  )
  .get(
    '/:id/stops',
    (request, response) => {
      let query = request.query || {};

      query.line = request.params.id;

      response.redirect(`/stops?${querystring.stringify(query)}`);
    }
  );
