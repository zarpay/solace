import { defineConfig } from 'vitepress';

export default defineConfig({
  base: '/solace/',
  title: 'Solace',
  description: 'A Ruby SDK for the Solana blockchain — keypairs, transactions, composers, and program clients in idiomatic Ruby.',
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
      { text: 'Concepts', link: '/concepts/keypairs-and-public-keys' },
      { text: 'Building Transactions', link: '/building/instruction-builders' },
      { text: 'Programs', link: '/programs/system-program' },
      { text: 'Reference', link: '/reference/codecs' },
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Quick Start', link: '/getting-started/' },
          { text: 'Conventions', link: '/conventions' },
        ],
      },
      {
        text: 'Core Concepts',
        items: [
          { text: 'Keypairs & Public Keys', link: '/concepts/keypairs-and-public-keys' },
          { text: 'Connection & RPC', link: '/concepts/connection-and-rpc' },
          { text: 'Transactions & Messages', link: '/concepts/transactions-and-messages' },
          { text: 'Instructions', link: '/concepts/instructions' },
          { text: 'Account Context', link: '/concepts/account-context' },
          { text: 'Address Lookup Tables', link: '/concepts/address-lookup-tables' },
        ],
      },
      {
        text: 'Building Transactions',
        items: [
          { text: 'Instruction Builders', link: '/building/instruction-builders' },
          { text: 'Composers', link: '/building/composers' },
          { text: 'The Transaction Composer', link: '/building/transaction-composer' },
          { text: 'Program Clients', link: '/building/program-clients' },
        ],
      },
      {
        text: 'Programs',
        items: [
          { text: 'System Program', link: '/programs/system-program' },
          { text: 'SPL Token', link: '/programs/spl-token' },
          { text: 'Token-2022', link: '/programs/token-2022' },
          { text: 'Associated Token Account', link: '/programs/associated-token-account' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Codecs', link: '/reference/codecs' },
          { text: 'PDA Derivation', link: '/reference/pda' },
          { text: 'Curve25519', link: '/reference/curve25519' },
          { text: 'Constants', link: '/reference/constants' },
          { text: 'Serialization', link: '/reference/serialization' },
          { text: 'Tokens', link: '/reference/tokens' },
          { text: 'Errors', link: '/reference/errors' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/zarpay/solace' },
    ],
    outline: {
      level: [2, 3],
      label: 'On this page',
    },
    docFooter: {
      prev: 'Previous page',
      next: 'Next page',
    },
    footer: {
      message: 'A Ruby SDK for Solana',
      copyright: 'Released under the MIT License',
    },
  },
});
