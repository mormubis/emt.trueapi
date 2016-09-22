const cache = new (require('./cache'))();
const request = require('request');

module.exports = (options = {}) => {
  const defer = Promise.defer();
  const key = `request:${JSON.stringify(options)}`;

  options.expiration = options.expiration || 60;

  cache
    .get(key)
    .then(defer.resolve)
    .catch(
      request.bind(
        request,
        options,
        (error, response, body) => {
          const isError = error != null;

          if (!isError) {
            cache.set(key, body, options.expiration);
          }

          defer[isError ? 'reject' : 'resolve'](isError ? error : body);
        }
      )
    );

  return defer.promise;
};
