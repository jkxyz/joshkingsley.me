const Metalsmith = require('metalsmith');
const inPlace = require('@metalsmith/in-place');
const collections = require('@metalsmith/collections');
const layouts = require('@metalsmith/layouts');
const markdown = require('@metalsmith/markdown');

const nunjucksOptions = {
  filters: {
    localeDateString (date, locale = 'ro-RO') {
      return date.toLocaleDateString(locale);
    },

    dateString (date) {
      return date.toDateString();
    }
  }
};

module.exports = Metalsmith(__dirname)
  .source('src')
  .destination('target')
  .clean(true)
  .use(markdown())
  .use(collections({
    posts: {
      pattern: 'blog/**/*.html',
      sortBy: 'date',
      filterBy: ({ draft }) => !draft,
      reverse: true
    }
  }))
  .use(inPlace({
    suppressNoFilesError: true,
    engineOptions: nunjucksOptions
  }))
  .use(layouts({
    default: 'post.njk',
    pattern: 'blog/**/*.html',
    suppressNoFilesError: true,
    engineOptions: nunjucksOptions
  }));
