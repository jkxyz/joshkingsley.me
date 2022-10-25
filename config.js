const Metalsmith = require('metalsmith');
const inPlace = require('@metalsmith/in-place');
const markdown = require('@metalsmith/markdown');
const collections = require('@metalsmith/collections');

module.exports = Metalsmith(__dirname)
  .source('src')
  .destination('target')
  .clean(true)
  .use(markdown())
  .use(collections({ posts: { pattern: 'blog/**/*.html' } }))
  .use(inPlace({ suppressNoFilesError: true }));
