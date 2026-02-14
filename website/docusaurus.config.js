const { themes: prismThemes } = require('prism-react-renderer');

const config = {
  title: 'Zorphy',
  tagline: 'Modern Dart code generation made approachable',
  url: 'https://arrrrny.github.io',
  baseUrl: '/zorphy',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'throw',
  favicon: 'img/favicon.ico',
  organizationName: 'zorphy',
  projectName: 'zorphy',
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: 'docs'
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css')
        }
      }
    ]
  ],
  themeConfig: {
        image: 'img/zuraffa-social-card.jpg',
    navbar: {
      title: 'Zorphy',
      logo: {
        alt: 'Giraffe logo',
        src: 'img/giraffe.svg'
      },
      items: [
        { to: '/docs/intro', label: 'Docs', position: 'left' },
        { to: '/docs/examples/basic', label: 'Examples', position: 'left' }
      ]
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Getting Started', to: '/docs/intro' },
            { label: 'Features', to: '/docs/features' }
          ]
        },
        {
          title: 'Examples',
          items: [
            { label: 'Basic', to: '/docs/examples/basic' },
            { label: 'JSON', to: '/docs/examples/json' },
            { label: 'Generics', to: '/docs/examples/generics' }
          ]
        }
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Zorphy`
    },
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'bash', 'json', 'yaml']
    }
  }
};

module.exports = config;
