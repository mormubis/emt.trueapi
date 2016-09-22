const app = require('../app');
const express = require('express');
const EMT = new (require('../emt'))(
  app.locals.EMT.client,
  app.locals.EMT.password
);
const filter = require('../lib/filter');
const latlng = require('../lib/latlng');
const radius = require('../lib/filter-radius');
const square = require('../lib/filter-square');

module.exports = new express.Router()
  .get(
    '/:id?',
    (request, response) => {
      const nelatlng = latlng(request.query.nelatlng);
      const origin = latlng(request.query.latlng);
      const regexp = new RegExp(request.query.name, 'i');
      const swlatlng = latlng(request.query.swlatlng);

      console.log(request.params.id);
      EMT.stops(request.query.line)
        .then(square(nelatlng, swlatlng))
        .then(radius(origin, request.query.radius))
        .then(
          filter(
            request.params.id,
            (stop) => stop.id === request.params.id
          )
        )
        .then(filter(request.query.name, (stop) => regexp.test(stop.name)))
        .then(response.json.bind(response))
        .catch(
          (e) => {
            console.error(e);
            response.sendStatus(500);
          }
        );
    }
  )
  .get(
    '/:id/arrives',
    (request, response) => {
      EMT.arrives(request.params.id)
        .then(response.json.bind(response))
        .catch(
          (e) => {
            console.error(e);
            response.sendStatus(500);
          }
        );
    }
  );
