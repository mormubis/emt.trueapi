const app = require('../app');
const express = require('express');
const EMT = app.locals.EMT;
const conditional = require('../lib/filter-conditional');
const latlng = require('../lib/latlng');
const radius = require('../lib/filter-radius');
const square = require('../lib/filter-square');

module.exports = new express.Router()
  .get('/:id?', function(request, response) {
    const id = Number(request.params.id);
    const line = Number(request.query.line);
    const name = request.query.name;
    const nelatlng = latlng(request.query.nelatlng);
    const origin = latlng(request.query.latlng);
    const regexp = new RegExp(name, 'i');
    const swlatlng = latlng(request.query.swlatlng);

    EMT.stops()
      // id filter
      .then(conditional(id, function(stop) {
        return stop.id === id;
      }))
      // line filter
      .then(conditional(line, function(stop) {
        return stop.lines.filter((value) => value.number === line).length !== 0;
      }))
      // coordinates filter
      .then(square(nelatlng, swlatlng))
      // radius filter
      .then(radius(origin, request.query.radius))
      // name filter
      .then(conditional(name, (stop) => regexp.test(stop.name)))
      // send
      .then(response.json.bind(response))
      // error
      .catch(console.error.bind(console))
      .catch(response.sendStatus.bind(response, 500));
  })
  .get('/:id/arrives', function(request, response) {
    EMT.arrives(request.params.id)
      // send
      .then(response.json.bind(response))
      // error
      .catch(console.error.bind(console))
      .catch(response.sendStatus.bind(response, 500));
  });
