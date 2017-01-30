const cache = new (require('./cache'))();
const request = require('request');

function Request(options = {}) {
  return new Promise(function(resolve, reject) {
    request(options, function(error, response, body) {
      if (!error) { resolve(body); }
      else { reject(error); }
    });
  });
}

module.exports = function CachedRequest(options = {}) {
  if (!options.expiration) { options.expiration = 60; }

  const key = `request:${JSON.stringify(options)}`;

  return cache
    .get(key)
    .catch(function() {
      return Request(options)
        .then(function(data) {
          cache.set(key, data, options.expiration);

          return data;
        });
    });
};
