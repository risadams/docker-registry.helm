import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';

const features = [
  {
    icon: '⎈',
    title: 'Gateway API first',
    body: 'Defaults to Kubernetes Gateway API (HTTPRoute) with automatic fallback to classic Ingress. One flag, three modes.',
  },
  {
    icon: '🔒',
    title: 'Secure by default',
    body: 'Hardened security contexts, read-only root filesystem, non-root UID, and dropped Linux capabilities out of the box.',
  },
  {
    icon: '📦',
    title: 'Multiple storage backends',
    body: 'Filesystem, S3 (with IRSA/instance-profile support), Azure Blob, and Swift — configured via a single values key.',
  },
  {
    icon: '🔁',
    title: 'HA ready',
    body: 'Stable haSharedSecret via lookup, Redis blob descriptor cache, StatefulSet mode, and HPA support for production scale.',
  },
  {
    icon: '📊',
    title: 'Prometheus native',
    body: 'Exposes a metrics endpoint and ships ServiceMonitor, PodMonitor, and PrometheusRule resources for full observability.',
  },
  {
    icon: '🧪',
    title: 'Thoroughly tested',
    body: 'Four-layer test suite: helm-lint, static analysis, helm-unittest, and kind cluster integration tests on every PR.',
  },
];

function Hero() {
  return (
    <div className="hero-banner">
      <h1 className="hero-title">Docker Registry Helm Chart</h1>
      <p className="hero-subtitle">
        A maintained Helm chart for deploying a private Docker Registry on
        Kubernetes. Fork of the upstream <code>twuni/docker-registry.helm</code>{' '}
        with production fixes and modern defaults.
      </p>

      <div className="hero-install">
        <code>helm repo add docker-registry https://risadams.github.io/docker-registry.helm</code>
        <code>helm repo update</code>
        <code>helm install my-registry docker-registry/docker-registry</code>
      </div>

      <div className="hero-buttons">
        <Link className="hero-button-primary" to="/docs/intro">
          Get started
        </Link>
        <Link className="hero-button-secondary" to="/docs/configuration">
          Configuration reference
        </Link>
        <Link
          className="hero-button-secondary"
          href="https://github.com/risadams/docker-registry.helm"
        >
          GitHub ↗
        </Link>
      </div>
    </div>
  );
}

function FeatureGrid() {
  return (
    <div className="feature-grid">
      {features.map(({ icon, title, body }) => (
        <div key={title} className="feature-card">
          <div className="feature-card-icon">{icon}</div>
          <p className="feature-card-title">{title}</p>
          <p className="feature-card-body">{body}</p>
        </div>
      ))}
    </div>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={siteConfig.tagline}>
      <main>
        <Hero />
        <FeatureGrid />
      </main>
    </Layout>
  );
}
