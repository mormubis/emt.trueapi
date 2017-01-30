const conditional = require('./filter-conditional');
const geolib = require('geolib');

function isInsideSquare(pointA, pointB, point) {
  const coordinates = [
    {latitude: pointA.latitude, longitude: pointB.longitude},
    {latitude: pointA.latitude, longitude: pointA.longitude},
    {latitude: pointB.latitude, longitude: pointA.longitude},
    {latitude: pointB.latitude, longitude: pointB.longitude}
  ];

  return geolib.isPointInside(point, coordinates);
}

function isInsideSquareBuilder(pointA, pointB) {
  return function check(point) {
    return isInsideSquare(pointA, pointB, point);
  };
}

module.exports = function builder(nelatlng, swlatlng) {
  return conditional(
    nelatlng && swlatlng,
    isInsideSquareBuilder(nelatlng, swlatlng)
  );
};
