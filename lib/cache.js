const NodeCache = require('node-cache');

module.exports = class Cache extends NodeCache {
  constructor() {
    super({stdTTL: 60, checkperiod: 120});
  }

  get() {
    const defer = Promise.defer();

    super.get(
      ...arguments,
      (error, data) => {
        const isError = error != null || data == null;

        defer[isError ? 'reject' : 'resolve'](isError ? error : data);
      }
    );

    return defer.promise;
  }
};
