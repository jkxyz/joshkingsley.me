const Metalsmith = require('metalsmith');
const inPlace = require('@metalsmith/in-place');
const collections = require('@metalsmith/collections');
const layouts = require('@metalsmith/layouts');
const markdown = require('@metalsmith/markdown');

module.exports = Metalsmith(__dirname)
  .source('src')
  .destination('target')
  .clean(true)
  .use(markdown())
  .use(collections({ posts: { pattern: 'blog/**/*.html' } }))
  .use(inPlace({ suppressNoFilesError: true }))
  .use(layouts({
    default: 'post.njk',
    pattern: 'blog/**/*.html',
    suppressNoFilesError: true
  }));
