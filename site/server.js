const http = require("http");
const serveStatic = require("serve-static");
const finalhandler = require("finalhandler");
const chokidar = require("chokidar");

function build() {
  return new Promise((resolve, reject) => {
    console.log("Building...");

    delete require.cache[require.resolve("./config")];

    const config = require("./config");

    config.build((err) => {
      if (err) return reject(err);
      console.log("Done");
      resolve();
    });
  });
}

chokidar
  .watch(["config.js", "layouts/**/*", "src/**/*"], { ignoreInitial: true })
  .on("all", () => {
    build().catch((err) => {
      console.error("Error during build:", err);
    });
  });

const staticHandler = serveStatic("target");

const server = http.createServer((req, res) => {
  staticHandler(req, res, finalhandler(req, res));
});

const port = process.env.PORT || 3000;

build().then(() => {
  server.listen(port, () => {
    console.log(`Listening on port ${port}`);
  });
});
