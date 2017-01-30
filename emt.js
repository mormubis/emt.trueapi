const moment = require('moment');
const request = require('./lib/request');

moment.locale('es');

module.exports = class EMT {
  constructor(client, password) {
    this.client = client;
    this.password = password;
  }

  static get URL() {
    return process.env.EMT_URL;
  }

  arrives(stop) {
    let options = {
      expiration: 1,
      url: '/geo/GetArriveStop.php'
    };

    if (stop !== null) { options.data = {idStop: stop}; }

    return this.request(options)
      // get result attribute
      .then((response) => response.arrives)
      // format results
      .then(function(response = []) {
        return response.map(function(value) {
          return {line: value.lineId, time: value.busTimeLeft};
        });
      });
  }

  lines(line, date = moment().format('L')) {
    let options = {
      data: {SelectDate: date},
      url: '/bus/GetListLines.php'
    };

    if (line != null) { options.data.Lines = line; }

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      // fix
      .then(function(response = []) {
        return Array.isArray(response) ? response : [response];
      })
      // format
      .then(function(response) {
        let lines = [];

        response.forEach(function(value) {
          const number = parseInt(value.line);

          lines[number] = {
            name: value.label,
            number,
            sources: [
              value.nameA.trim(),
              value.nameB.trim()
            ]
          };
        });

        return line ? lines[line] : lines.filter(value => value != null);
      });
  }

  nodes(line) {
    const options = {url: '/bus/GetRouteLinesRoute.php'};

    if (line !== null) { options.data = {Lines: line}; }

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      // format
      .then(function(response = []) {
        return response.map(function(value) {
          return {
            isForward: value.secDetail < 20,
            latitude: value.latitude,
            longitude: value.longitude
          };
        });
      });
  }

  request(options = {}) {
    return request(
      Object.assign(
        {
          expiration: 24 * 60 * 60,
          form: this.sign(options.data),
          json: true,
          method: 'POST',
          strictSSL: false
        },
        options,
        {url: `${EMT.URL}${options.url}`}
      )
    );
  }

  sign(data = {}) {
    return Object.assign(
      {idClient: this.client, passKey: this.password},
      data
    );
  }

  stops(date = moment().format('L')) {
    let options = {
      data: {SelectDate: date},
      url: '/bus/GetNodesLines.php'
    };

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      // format
      .then(function(response) {
        return response.map(function(value) {
          const lines = value.lines
            .filter((value) => !!value)
            .map(function(line) {
              const [number, direction] = line.split('/');

              return {isForward: direction === '1', number: Number(number)};
            });

          return {
            id: value.node,
            name: value.name,
            lines,
            latitude: value.latitude,
            longitude: value.longitude
          };
        });
      });
  }
};
