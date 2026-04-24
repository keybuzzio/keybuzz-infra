const fs = require('fs');

const filePath = '/opt/keybuzz/keybuzz-website/src/app/pricing/page.tsx';
let code = fs.readFileSync(filePath, 'utf8');

// 1. Add useEffect to react import
code = code.replace(
  'import { useState } from "react";',
  'import { useState, useEffect } from "react";'
);

// 2. Add UTM state + effect after the first useState in the component
// Find the isAnnual useState and add UTM logic right after
const utmBlock = `
  // UTM forwarding: capture UTM params from URL to forward to registration links
  const [utmSuffix, setUtmSuffix] = useState("");
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"];
    const pairs = utmKeys
      .filter(k => params.has(k))
      .map(k => k + "=" + encodeURIComponent(params.get(k)));
    if (pairs.length > 0) setUtmSuffix("&" + pairs.join("&"));
  }, []);
`;

code = code.replace(
  'const [isAnnual, setIsAnnual] = useState(false);',
  'const [isAnnual, setIsAnnual] = useState(false);' + utmBlock
);

// 3. Append utmSuffix to plan CTA links (the href in the plan cards)
code = code.replace(
  "href={plan.ctaLink.replace('cycle=monthly', `cycle=${isAnnual ? 'yearly' : 'monthly'}`)}",
  "href={plan.ctaLink.replace('cycle=monthly', `cycle=${isAnnual ? 'yearly' : 'monthly'}`) + utmSuffix}"
);

fs.writeFileSync(filePath, code, 'utf8');
console.log('PRICING UTM PATCH: applied OK');

// Verify
const result = fs.readFileSync(filePath, 'utf8');
console.log('useEffect imported:', result.includes('useEffect'));
console.log('utmSuffix state:', result.includes('utmSuffix'));
console.log('utmSuffix in href:', result.includes('+ utmSuffix'));
console.log('Enterprise link untouched:', result.includes('href={enterprise.ctaLink}'));
