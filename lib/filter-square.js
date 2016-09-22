const filter = require('./filter');
const geolib = require('geolib');

module.exports = (nelatlng, swlatlng) => {
  let coordinates;

  if (nelatlng && swlatlng) {
    coordinates = [
      {latitude: nelatlng.latitude, longitude: swlatlng.longitude},
      {latitude: nelatlng.latitude, longitude: nelatlng.longitude},
      {latitude: swlatlng.latitude, longitude: nelatlng.longitude},
      {latitude: swlatlng.latitude, longitude: swlatlng.longitude}
    ];
  }

  return filter(
    nelatlng && swlatlng,
    (value) => {
      return geolib.isPointInside(value, coordinates);
    }
  );
};
