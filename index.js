const app = require('./app');
const bodyParser = require('body-parser');
const EMT = require('./emt');
const morgan = require('morgan');

app.locals.EMT = new EMT(process.env.EMT_CLIENT, process.env.EMT_PASSWORD);

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
  .listen(3000);
