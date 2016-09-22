const moment = require('moment');
const request = require('./lib/request');

moment.locale('es');

module.exports = class EMT {
  constructor(client, password) {
    this.client = client;
    this.password = password;
  }

  static get URL() {
    return 'https://openbus.emtmadrid.es:9443/emt-proxy-server/last';
  }

  arrives(stop) {
    let options = {
      url: '/geo/GetArriveStop.php'
    };

    if (stop !== null) {
      options.data = {idStop: stop};
    }

    return this.request(options)
      // get result attribute
      .then((res) => res.arrives)
      // format results
      .then(
        (response) => {
          return response.map(
            (value) => {
              return {line: value.lineId, time: value.busTimeLeft};
            }
          );
        }
      );
  }

  lines(line, date = moment().format('L')) {
    let options = {
      data: {
        SelectDate: date
      },
      url: '/bus/GetListLines.php'
    };

    if (line != null) {
      options.data.Lines = line;
    }

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      // fix
      .then(
        (response = []) => {
          if (!Array.isArray(response)) {
            response = [response];
          }

          return response;
        }
      )
      // format
      .then(
        (response) => {
          let lines = [];

          response.forEach(
            (value)=> {
              const number = parseInt(value.line);

              lines[number] = {
                name: value.label,
                number,
                sources: [
                  value.nameA.trim(),
                  value.nameB.trim()
                ]
              };
            }
          );

          return lines;
        }
      );
  }

  nodes(line) {
    let options = {
      url: '/bus/GetRouteLinesRoute.php'
    };

    if (line !== null) {
      options.data = {Lines: line};
    }

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      // format
      .then(
        (response = []) => {
          return response.map(
            (value) => {
              return {
                isForward: value.secDetail < 20,
                latitude: value.latitude,
                longitude: value.longitude
              };
            }
          );
        }
      );
  }

  request(options = {}) {
    options = Object.assign({}, options);

    options.form = this.sign(options.data);
    options.json = true;
    options.method = 'POST';
    options.strictSSL = false;
    options.url = `${EMT.URL}${options.url}`;

    return request(options);
  }

  sign(data = {}) {
    data = Object.assign({}, data);

    data.idClient = this.client;
    data.passKey = this.password;

    return data;
  }

  stops(line, date = moment().format('L')) {
    let options = {
      data: {SelectDate: date},
      url: line !== null ? '/bus/GetRouteLines.php' : '/bus/GetNodesLines.php'
    };

    if (line !== null) {
      options.data.Lines = line;
    }

    return this.request(options)
      // get result attribute
      .then((response) => response.resultValues)
      .then(
        (response) => {
          return response.map(
            (value) => {
              let lines = [
                {
                  line: value.line,
                  isForward: value.secDetails === 10
                }
              ];

              if (value.lines != null) {
                lines = value.lines.map(
                  (line) => {
                    line = line.split('/');

                    return {isForward: line[1] === '1', number: line[0]};
                  }
                );
              }

              return {
                id: value.node,
                name: value.name,
                lines,
                latitude: value.latitude,
                longitude: value.longitude
              };
            }
          );
        }
      );
  }
};
