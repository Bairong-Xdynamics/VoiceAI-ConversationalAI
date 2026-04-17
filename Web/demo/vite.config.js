/* eslint-disable import/no-extraneous-dependencies -- demo devDependencies */
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import basicSsl from '@vitejs/plugin-basic-ssl';
import { defineConfig } from 'vite';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig(({ command, isPreview }) => ({
  define: {
    __VOICE_REALTIME_SDK_VERSION__: '"3.0.1"'
  },
  plugins: [
    command === 'serve' && !isPreview ? basicSsl() : null
  ].filter(Boolean),
  root: __dirname,
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: true
  },
  server: {
    port: 5174,
    host: true,
    https: true,
    open: true
  },
  preview: {
    host: true,
    port: 5174
  }
}));
