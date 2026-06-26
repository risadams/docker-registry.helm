import React from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';

export default function NavbarLogo() {
  const logoSrc = useBaseUrl('/img/logo.svg');
  return (
    <Link className="navbar__brand" to="/">
      <img
        className="navbar__logo"
        src={logoSrc}
        alt="Docker Registry Helm Chart"
        width="32"
        height="32"
      />
      <b className="navbar__title">
        Docker <em className="navbar__title-em">Registry</em>
      </b>
    </Link>
  );
}
