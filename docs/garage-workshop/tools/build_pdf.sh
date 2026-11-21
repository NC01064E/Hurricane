#!/usr/bin/env bash
# Builds garage-workshop-plan-corrected.pdf from the markdown + SVGs. Needs pandoc and Playwright (Chromium).
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
cat > "$TMP/style.css" <<'CSS'
body{font:11pt/1.45 Helvetica,Arial,sans-serif;max-width:7.4in;margin:0 auto;color:#1b1b1b}
h1{font-size:20pt;border-bottom:2px solid #0b5cab;padding-bottom:4px;margin-top:0}
h2{font-size:14pt;color:#0b5cab;margin-top:1.3em}h3{font-size:11.5pt}
table{border-collapse:collapse;width:100%;font-size:9pt;margin:8px 0;page-break-inside:auto}
th,td{border:1px solid #c9ced6;padding:3px 6px;vertical-align:top}th{background:#eef3f8;text-align:left}
tr{page-break-inside:avoid}code{font-size:9pt;background:#f1f3f5;padding:0 3px}
blockquote{border-left:3px solid #b45309;margin:8px 0;padding:2px 10px;color:#444;background:#fdf6ec}
img{max-width:100%;height:auto}.pb{page-break-before:always}
details>summary{font-weight:bold}
CSS
{
 cat PLAN.md
 printf '\n<div class="pb"></div>\n\n# Schematics\n\n'
 for f in drawings/schematic-1-floor-plan.svg drawings/schematic-2-wall-elevation.svg drawings/schematic-3-leaf.svg; do printf '![](%s)\n\n' "$f"; done
 printf '\n<div class="pb"></div>\n\n'; cat SIZING.md
 printf '\n<div class="pb"></div>\n\n'; cat CUTLIST.md
 printf '\n<div class="pb"></div>\n\n'; cat BUDGET.md
 printf '\n<div class="pb"></div>\n\n'; cat CHECKLIST.md
 printf '\n<div class="pb"></div>\n\n'; cat AUDIT.md
} > "$TMP/all.md"
pandoc "$TMP/all.md" -f gfm -t html5 -s --embed-resources --resource-path=. -c "$TMP/style.css" \
  --metadata pagetitle="Garage Workshop Conversion - corrected plan" -o "$TMP/all.html"
cat > "$TMP/pdf.js" <<'JS'
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  const p = await b.newPage();
  await p.goto('file://' + process.argv[2]);
  await p.evaluate(() => document.querySelectorAll('details').forEach(d => d.open = true));
  await p.pdf({ path: process.argv[3], format: 'Letter', printBackground: true, margin: { top: '0.6in', bottom: '0.6in', left: '0.5in', right: '0.5in' },
    displayHeaderFooter: true, headerTemplate: '<span></span>',
    footerTemplate: '<div style="font-size:8px;width:100%;text-align:center;color:#666">Garage Workshop Conversion - corrected plan - <span class="pageNumber"></span>/<span class="totalPages"></span></div>' });
  await b.close();
})();
JS
NODE_PATH="$(npm root -g)" node "$TMP/pdf.js" "$TMP/all.html" "$PWD/garage-workshop-plan-corrected.pdf"
ls -l garage-workshop-plan-corrected.pdf
