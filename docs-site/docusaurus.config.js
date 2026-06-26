// @ts-check
const { themes: prismThemes } = require('prism-react-renderer');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Docker Registry',
  tagline: 'A maintained Helm chart for deploying a private Docker Registry on Kubernetes.',
  favicon: 'img/favicon.svg',

  url: 'https://risadams.github.io',
  baseUrl: '/docker-registry.helm/',

  organizationName: 'risadams',
  projectName: 'docker-registry.helm',

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  headTags: [
    {
      tagName: 'link',
      attributes: {
        rel: 'stylesheet',
        type: 'text/css',
        href: 'https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,400;1,9..144,500&family=Caveat:wght@400;600;700&family=JetBrains+Mono:wght@400;500&family=Crimson+Pro:ital,wght@0,400;0,500;0,600;1,400;1,500&display=swap'
      },
    }
  ],

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: '../docs',
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/risadams/docker-registry.helm/edit/main/',
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/social-card.png',
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: false,
        respectPrefersColorScheme: false,
      },
      navbar: {
        title: 'Docker Registry',
        logo: {
          alt: 'Docker Registry Helm Chart',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'mainSidebar',
            position: 'left',
            label: 'Docs',
          },
          {
            href: 'https://github.com/risadams/docker-registry.helm/blob/main/CHANGELOG.md',
            label: 'Changelog',
            position: 'left',
          },
          {
            href: 'https://github.com/risadams/docker-registry.helm',
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Documentation',
            items: [
              { label: 'Introduction',    to: '/docs/intro' },
              { label: 'Configuration',   to: '/docs/configuration' },
              { label: 'Usage Examples',  to: '/docs/usage' },
              { label: 'Design Decisions', to: '/docs/adr/README' },
            ],
          },
          {
            title: 'Project',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/risadams/docker-registry.helm',
              },
              {
                label: 'Changelog',
                href: 'https://github.com/risadams/docker-registry.helm/blob/main/CHANGELOG.md',
              },
              {
                label: 'Issues',
                href: 'https://github.com/risadams/docker-registry.helm/issues',
              },
              {
                label: 'Upstream (twuni)',
                href: 'https://github.com/twuni/docker-registry.helm',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Ris Adams. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.oneLight,
        darkTheme: prismThemes.gruvboxMaterialDark,
        additionalLanguages: ['bash', 'yaml', 'json'],
      },
    }),
};

module.exports = config;
