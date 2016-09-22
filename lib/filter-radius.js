const filter = require('./filter');
const geolib = require('geolib');

module.exports = (origin, radius = 250) => {
  return filter(
    origin,
    (value) => {
      return geolib.getDistance(value, origin) <= radius;
    }
  );
};
