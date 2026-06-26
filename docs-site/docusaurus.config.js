// @ts-check
const fs = require('fs');
const path = require('path');
const { themes: prismThemes } = require('prism-react-renderer');

// Read chart version from Chart.yaml at build time
const chartYaml = fs.readFileSync(path.resolve(__dirname, '../Chart.yaml'), 'utf8');
const chartVersion = chartYaml.match(/^version:\s*(.+)$/m)?.[1]?.trim() ?? '0.0.0';
const appVersion  = chartYaml.match(/^appVersion:\s*(.+)$/m)?.[1]?.trim() ?? '0.0.0';

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
        title: '',
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
            type: 'html',
            position: 'right',
            value: `<span class="navbar-version-badge">v${chartVersion}</span>`,
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
        links: [],
        copyright: `
          <div class="footer-bar">
            <div class="footer-bar__brand">
              <svg viewBox="0 0 44 44" width="20" height="20" aria-hidden="true">
                <polygon points="22,5 33,11.5 33,26.5 22,33 11,26.5 11,11.5" fill="#CB0162" opacity=".85"></polygon>
                <text x="22" y="23.5" text-anchor="middle" font-family="'JetBrains Mono',monospace" font-size="10" font-weight="600" fill="#faf6ef">DR</text>
              </svg>
              <span>Docker <em>Registry</em> Helm Chart</span>
            </div>
            <nav class="footer-bar__links" aria-label="Footer navigation">
              <a href="https://github.com/risadams/docker-registry.helm">GitHub</a>
              <a href="https://github.com/risadams/docker-registry.helm/blob/main/CHANGELOG.md">Changelog</a>
              <a href="https://github.com/risadams/docker-registry.helm/issues">Issues</a>
              <a href="https://github.com/twuni/docker-registry.helm">Upstream (twuni)</a>
            </nav>
            <div class="footer-bar__copy">© ${new Date().getFullYear()} Ris Adams · chart v${chartVersion} · registry v${appVersion}</div>
          </div>
        `,
      },
      prism: {
        theme: prismThemes.oneLight,
        darkTheme: prismThemes.gruvboxMaterialDark,
        additionalLanguages: ['bash', 'yaml', 'json'],
      },
    }),
};

module.exports = config;
