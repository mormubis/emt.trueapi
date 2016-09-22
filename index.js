const app = require('./app');
const bodyParser = require('body-parser');
const fs = require('fs');
const moment = require('moment');
const morgan = require('morgan');

app.locals.EMT = JSON.parse(fs.readFileSync('./credentials.json', 'utf8'));

app
// Setup
  .use(bodyParser.urlencoded({extended: true}))
  .use(morgan('combined'))
  // Content
  .use('/lines', require('./controllers/lines'))
  .use('/stops', require('./controllers/stops'))
  // Fallback
  // .all('/', require('./controllers/index'))
  .all('*', (req, res) => res.sendStatus(404))
  // Run
  .listen();
