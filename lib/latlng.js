module.exports = (latlng) => {
  if (latlng == null) {
    return null;
  }

  latlng = latlng || '';
  latlng = latlng.split(',');

  return {
    latitude: latlng[0] || 0,
    longitude: latlng[1] || 0
  };
};
