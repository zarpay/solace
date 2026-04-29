import { defineConfig } from 'vitepress';

export default defineConfig({
  base: '/solace/',
  title: 'Solace',
  description: 'A Ruby SDK for the Solana blockchain',
  lang: 'en-US',
  cleanUrls: true,
  lastUpdated: true,
  appearance: false,
  vite: {
    server: {
      allowedHosts: true,
    },
  },
  themeConfig: {
    siteTitle: 'Solace',
    search: {
      provider: 'local',
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Quick Start', link: '/getting-started/' },
      { text: 'Core', link: '/core/keypairs' },
      { text: 'Composers', link: '/composers/overview' },
      { text: 'Programs', link: '/programs/spl-token' },
      { text: 'Utilities', link: '/utilities/codecs' },
      { text: 'Reference', link: '/reference/constants' },
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Home', link: '/' },
          { text: 'Quick Start', link: '/getting-started/' },
          { text: 'Developer Setup', link: '/getting-started/developer-setup' },
          { text: 'Architecture', link: '/getting-started/architecture' },
        ],
      },
      {
        text: 'Core',
        items: [
          { text: 'Keypairs', link: '/core/keypairs' },
          { text: 'Connections', link: '/core/connections' },
          { text: 'Transactions', link: '/core/transactions' },
          { text: 'Messages', link: '/core/messages' },
          { text: 'Instructions', link: '/core/instructions' },
        ],
      },
      {
        text: 'Composers',
        items: [
          { text: 'Overview', link: '/composers/overview' },
          { text: 'Custom Composers', link: '/composers/custom' },
        ],
      },
      {
        text: 'Programs',
        items: [
          { text: 'SPL Token', link: '/programs/spl-token' },
          { text: 'Associated Token Account', link: '/programs/ata' },
        ],
      },
      {
        text: 'Utilities',
        items: [
          { text: 'Codecs', link: '/utilities/codecs' },
          { text: 'PDA', link: '/utilities/pda' },
          { text: 'Curve25519', link: '/utilities/curve25519' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Constants', link: '/reference/constants' },
          { text: 'Errors', link: '/reference/errors' },
          { text: 'Serializers', link: '/reference/serializers' },
        ],
      },
    ],
    socialLinks: [{ icon: 'github', link: 'https://github.com/zarpay/solace' }],
    outline: {
      level: [2, 3],
      label: 'On this page',
    },
    docFooter: {
      prev: 'Previous page',
      next: 'Next page',
    },
    footer: {
      message: 'Developed at and used extensively by <a href="https://zar.app">ZAR</a>',
      copyright: 'Released under the MIT License',
    },
  },
});
