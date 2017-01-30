const filter = require('./filter');

function identity(value) {
  return value;
}

module.exports = function builder(condition, predicate) {
  return condition ? filter(predicate) : identity;
};
