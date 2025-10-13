import { defineConfig } from 'vite'

export default defineConfig({
  // Build configuration
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['./src/main.js']
        }
      }
    }
  },
  
  // Server configuration for development
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    hmr: {
      port: 5173
    },
    proxy: {
      // Forward /api to Django backend when running `npm run dev`
      '/api': {
        target: process.env.VITE_API_BASE_URL || 'http://localhost:8000',
        changeOrigin: true,
        secure: false,
        // Keep path as-is
        rewrite: (path) => path,
      },
    }
  },
  
  // Preview configuration
  preview: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true
  },
  
  // Base public path
  base: '/',
  
  // Define global constants
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
  },
})
