const NodeCache = require('node-cache');

module.exports = class Cache extends NodeCache {
  constructor() {
    super({stdTTL: 60, checkperiod: 120});
  }

  get() {
    return new Promise((resolve, reject) => {
      super.get(
        ...arguments,
        function(error, data) {
          if (!error && data !== undefined) { resolve(data); }
          else { reject(error); }
        }
      );
    });
  }
};
