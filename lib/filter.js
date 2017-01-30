module.exports = function builder(predicate) {
  return function filter(collection = []) {
    return collection.filter(predicate);
  };
};
