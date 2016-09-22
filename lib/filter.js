module.exports = (needle, predicate) => {
  return (collection = []) => {
    return needle != null ? collection.filter(predicate) : collection;
  };
};
