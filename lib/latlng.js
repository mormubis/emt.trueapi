module.exports = function toLatLng(string) {
  if (typeof string !== 'string') { return null; }

  const [latitude, longitude] = string.split(',');

  return {latitude, longitude};
};
