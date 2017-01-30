const app = require('../app');
const conditional = require('../lib/filter-conditional');
const express = require('express');
const EMT = app.locals.EMT;
const querystring = require('querystring');
const latlng = require('../lib/latlng');
const square = require('../lib/filter-square');

module.exports = new express.Router()
  .get('/:id?', function(request, response) {
    EMT.lines(request.params.id)
      // send
      .then(response.json.bind(response))
      // error
      .catch(console.error.bind(console))
      .catch(response.sendStatus.bind(response, 500));
  })
  .get('/:id/nodes', function(request, response) {
    const nelatlng = latlng(request.query.nelatlng);
    const swlatlng = latlng(request.query.swlatlng);

    EMT.nodes(request.params.id)
      // coordinates filter
      .then(square(nelatlng, swlatlng))
      // send
      .then(response.json.bind(response))
      // error
      .catch(console.error.bind(console))
      .catch(response.sendStatus.bind(response, 500));
  })
  .get('/:id/stops', function(request, response) {
    let query = request.query || {};

    query.line = request.params.id;

    response.redirect(`/stops?${querystring.stringify(query)}`);
  });
