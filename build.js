const config = require('./config');

config.build((err) => {
  if (err) {
    throw err;
  }
});
