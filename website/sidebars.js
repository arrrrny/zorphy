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
      type: 'doc',
      id: 'vs-freezed',
      label: 'Zorphy vs Freezed'
    },
    {
      type: 'doc',
      id: 'migrating-from-freezed',
      label: 'Migrating from Freezed'
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        'examples/comprehensive',
        'examples/domain-gallery',
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
