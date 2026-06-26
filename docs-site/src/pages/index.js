import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';

const features = [
  {
    icon: '⎈',
    title: 'Gateway API first',
    body: 'Kubernetes Gateway API (HTTPRoute) with automatic fallback to classic Ingress. One flag, three modes.',
  },
  {
    icon: '🔒',
    title: 'Secure by default',
    body: 'Hardened security contexts, read-only root filesystem, non-root UID, and dropped Linux capabilities out of the box.',
  },
  {
    icon: '📦',
    title: 'Multiple storage backends',
    body: 'Filesystem, S3 (with IRSA support), Azure Blob, and Swift — configured via a single values key.',
  },
  {
    icon: '🔁',
    title: 'HA ready',
    body: 'Stable haSharedSecret via lookup, Redis descriptor cache, StatefulSet mode, and HPA support for production scale.',
  },
  {
    icon: '📊',
    title: 'Prometheus native',
    body: 'Metrics endpoint plus ServiceMonitor, PodMonitor, and PrometheusRule resources for full observability.',
  },
  {
    icon: '🧪',
    title: 'Thoroughly tested',
    body: 'Four-layer test suite: helm-lint, static analysis, helm-unittest, and kind cluster integration tests on every PR.',
  },
];

const docLinks = [
  {
    title: 'Introduction',
    desc: 'Get started and understand the defaults.',
    to: '/docs/intro',
    accent: 'rose',
  },
  {
    title: 'Configuration',
    desc: 'Full reference for all values.yaml keys.',
    to: '/docs/configuration',
    accent: 'navy',
  },
  {
    title: 'Usage Examples',
    desc: 'Common deployment patterns and configs.',
    to: '/docs/usage',
    accent: 'plum',
  },
  {
    title: 'Design Decisions',
    desc: 'ADRs explaining architectural choices.',
    to: '/docs/adr/README',
    accent: 'amber',
  },
];

function Hero() {
  return (
    <section className="hero-banner">
      <div className="hero-eyebrow">helm chart for kubernetes</div>
      <h1 className="hero-title">
        Docker<br />
        <em className="hero-title-em">Registry.</em>
      </h1>
      <p className="hero-subtitle">
        A maintained fork of{' '}
        <em>twuni/docker-registry.helm</em> with production hardening,
        modern Kubernetes defaults, and a four-layer test suite.
      </p>
      <div className="hero-buttons">
        <Link className="hero-button-primary" to="/docs/intro">
          Get started
        </Link>
        <Link className="hero-button-secondary" to="/docs/configuration">
          Configuration reference
        </Link>
      </div>
    </section>
  );
}

function QuickInstall() {
  return (
    <section className="quick-install-section">
      <div className="quick-install-block">
        <div className="quick-install-label">Quick install</div>
        <pre className="quick-install-pre">{
`# Add the Helm repository
helm repo add docker-registry https://risadams.github.io/docker-registry.helm
helm repo update

# Install with defaults
helm install my-registry docker-registry/docker-registry`
        }</pre>
      </div>
    </section>
  );
}

function FeaturesSection() {
  return (
    <section className="features-section">
      <div className="features-header">
        <div className="features-eyebrow">what you get</div>
        <h2 className="features-heading">
          Built for <em className="features-heading-em">production.</em>
        </h2>
        <p className="features-subtitle">
          Everything you need to run a reliable, secure, and observable
          private registry on Kubernetes — out of the box.
        </p>
      </div>
      <div className="feature-grid">
        {features.map(({ icon, title, body }) => (
          <div key={title} className="feature-card">
            <div className="feature-card-icon">{icon}</div>
            <p className="feature-card-title">{title}</p>
            <p className="feature-card-body">{body}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function DocLinksSection() {
  return (
    <section className="doc-links-section">
      <h2 className="doc-links-heading">Documentation</h2>
      <div className="doc-links-grid">
        {docLinks.map(({ title, desc, to, accent }) => (
          <Link key={title} className={`doc-card doc-card--${accent}`} to={to}>
            <div className="doc-card-title">{title}</div>
            <div className="doc-card-desc">{desc}</div>
          </Link>
        ))}
      </div>
    </section>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={siteConfig.tagline}>
      <main>
        <Hero />
        <QuickInstall />
        <FeaturesSection />
        <DocLinksSection />
      </main>
    </Layout>
  );
}
