# KavachBot React Frontend Layer
**Under: DigiKavach Technologies Private Limited**
**Project Lead & Verifier: Sarath**
**Development Team: Sai, Mohan, Siva, Avi, etc. (Sudo names)**

This directory contains the modernized client-side web application for `KavachBot`, built using React, Vite, and glassmorphism styling.

---

## File Architecture

- **`index.html`**: Host HTML page for the React app context.
- **`vite.config.js`**: Configuration mapping plugins, dev server ports, and proxying `/api` backend requests to `http://127.0.0.1:8000`.
- **`src/main.jsx`**: Bootstrapping loader linking React context to host DOM.
- **`src/App.jsx`**: Central single-page-app layout enclosing:
  - Authorization views (Login, Register panels).
  - Main Dashboard (Evaluator form, scan history panel, and PDF report downloads).
  - Blacklist Manager (Exclusive viewport for admin users to blacklist numbers and URLs).
- **`src/index.css`**: Design system tokens for dark glassmorphism styling, outfit/inter typography, and keyframe animations.

---

## Local Setup & Development

1. Install Node.js dependencies:
   ```bash
   npm install
   ```
2. Start the Vite hot-reloading development server:
   ```bash
   npm run dev
   ```
3. Compile production assets:
   ```bash
   npm run build
   ```
