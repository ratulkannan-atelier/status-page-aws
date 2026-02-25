const express = require('express');
const morgan = require('morgan');
const { getDateTime, initDb } = require('./db');
const { startScheduler } = require('./scheduler');
const monitorsRouter = require('./routes/monitors');
const checksRouter = require('./routes/checks');

const app = express();
const port = process.env.PORT || 3000;

app.use(morgan('tiny'));
app.use(express.json());

app.get('/', async (req, res) => {
  const dateTime = await getDateTime();
  const response = dateTime;
  response.api = 'node';
  res.send(response);
});

app.get('/ping', async (_, res) => {
  res.send('pong');
});

app.use('/monitors', monitorsRouter);
app.use('/checks', checksRouter);

initDb().then(() => {
  const server = app.listen(port, () => {
    console.log(`Status page API listening on port ${port}`);
  });

  const stopScheduler = startScheduler();

  process.on('SIGTERM', () => {
    console.debug('SIGTERM signal received: closing HTTP server');
    stopScheduler();
    server.close(() => {
      console.debug('HTTP server closed');
    });
  });
});
