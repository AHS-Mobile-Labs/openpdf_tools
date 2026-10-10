#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=========================================="
echo " Building OpenPDF Tools for GitHub Pages  "
echo "=========================================="

flutter build web --release --base-href "/openpdf_tools/"

# Disable Jekyll processing on GitHub Pages
touch build/web/.nojekyll

# Ensure SPA subpaths resolve correctly without 404
cp build/web/index.html build/web/404.html

echo "=========================================="
echo " Deploying build/web to 'gh-pages' branch "
echo "=========================================="

cd build/web
rm -rf .git
git init
git checkout -b gh-pages
git add -A
git commit -m "Deploy OpenPDF Tools to GitHub Pages - $(date -u '+%Y-%m-%d %H:%M:%SZ')"
git remote add origin https://github.com/AHS-Mobile-Labs/openpdf_tools.git
git push -u origin gh-pages --force
rm -rf .git

cd "$REPO_ROOT"

echo "=========================================="
echo " Deployment to gh-pages branch complete!   "
echo " Live URL: https://ahs-mobile-labs.github.io/openpdf_tools/ "
echo "=========================================="
