const conditional = require('./filter-conditional');
const geolib = require('geolib');

function isWithin(origin, target, distance) {
  return geolib.getDistance(origin, target) <= distance;
}

function isWithinCircleBuilder(origin, radius) {
  return function check(point) {
    return isWithin(origin, point, radius);
  };
}

module.exports = function builder(origin, radius = 250) {
  return conditional(
    !!origin,
    isWithinCircleBuilder(origin, radius)
  );
};
