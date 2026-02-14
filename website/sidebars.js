const sidebars = {
  docs: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Getting Started'
    },
    {
      type: 'doc',
      id: 'features',
      label: 'Features'
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        'examples/basic',
        'examples/json',
        'examples/enums',
        'examples/nested',
        'examples/polymorphism',
        'examples/generics',
        'examples/filters-and-query',
        'examples/compare-to',
        'examples/patches',
        'examples/factories-and-constructors',
        'examples/defaults-and-converters',
        'examples/nullability-and-hash',
        'examples/static-methods'
      ]
    }
  ]
};

module.exports = sidebars;
