const Metalsmith = require('metalsmith');
const inPlace = require('@metalsmith/in-place');

Metalsmith(__dirname)
  .source('src')
  .destination('build')
  .clean(true)
  .use(inPlace({ suppressNoFilesError: true }))
  .build(err => {
    if (err) throw err;
    console.log('Build finished');
  });
