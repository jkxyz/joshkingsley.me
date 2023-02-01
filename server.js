const nodeStatic = require('node-static');
const http = require('http');
const chokidar = require('chokidar');

function build () {
  delete require.cache[require.resolve('./config')];
  const config = require('./config');
  config.build(err => {
    if (err) throw err;
  });
}

build();

chokidar
  .watch(['config.js', 'layouts/**/*', 'src/**/*'], { ignoreInitial: true })
  .on('all', () => {
    build();
  });

const fileServer = new nodeStatic.Server('target', { cache: false });

http
  .createServer((req, res) => {
    req
      .addListener('end', () => { fileServer.serve(req, res); })
      .resume();
  })
  .listen(3000, () => {
    console.log('Listening on port 3000');
  });
