const fs = require('fs');
const path = require('path');

const BASE = '/opt/keybuzz/keybuzz-website/src';

// ============================================================
// 1. Create global-error.tsx (root-level error boundary)
// ============================================================
const globalError = `"use client";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="fr">
      <body className="min-h-screen flex items-center justify-center bg-white">
        <div className="text-center px-6">
          <h2 className="text-2xl font-bold text-slate-900 mb-4">
            Une erreur est survenue
          </h2>
          <p className="text-slate-600 mb-6">
            Le chargement de la page a rencontré un problème.
          </p>
          <div className="flex gap-3 justify-center">
            <button
              onClick={() => reset()}
              className="px-6 py-2.5 bg-[#26a9e0] text-white rounded-lg hover:bg-[#1e8fc0] transition-colors font-medium"
            >
              Réessayer
            </button>
            <button
              onClick={() => window.location.reload()}
              className="px-6 py-2.5 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors font-medium"
            >
              Recharger la page
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
`;

fs.writeFileSync(path.join(BASE, 'app/global-error.tsx'), globalError, 'utf8');
console.log('1. Created global-error.tsx');

// ============================================================
// 2. Create error.tsx (route-level error boundary)
// ============================================================
const routeError = `"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="min-h-[60vh] flex items-center justify-center">
      <div className="text-center px-6">
        <h2 className="text-xl font-bold text-slate-900 mb-4">
          Erreur de chargement
        </h2>
        <p className="text-slate-600 mb-6">
          Cette page n&apos;a pas pu se charger correctement.
        </p>
        <div className="flex gap-3 justify-center">
          <button
            onClick={() => reset()}
            className="px-6 py-2.5 bg-[#26a9e0] text-white rounded-lg hover:bg-[#1e8fc0] transition-colors font-medium"
          >
            Réessayer
          </button>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-2.5 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors font-medium"
          >
            Recharger la page
          </button>
        </div>
      </div>
    </div>
  );
}
`;

fs.writeFileSync(path.join(BASE, 'app/error.tsx'), routeError, 'utf8');
console.log('2. Created error.tsx');

// ============================================================
// 3. Fix CookieConsent - wrap localStorage in try-catch
// ============================================================
let cookie = fs.readFileSync(path.join(BASE, 'components/CookieConsent.tsx'), 'utf8');

cookie = cookie.replace(
  `    const stored = localStorage.getItem(CONSENT_KEY);`,
  `    let stored: string | null = null;
    try { stored = localStorage.getItem(CONSENT_KEY); } catch { /* storage blocked */ }`
);

cookie = cookie.replace(
  `    localStorage.setItem(CONSENT_KEY, JSON.stringify(data));`,
  `    try { localStorage.setItem(CONSENT_KEY, JSON.stringify(data)); } catch { /* storage blocked */ }`
);

cookie = cookie.replace(
  `    localStorage.removeItem(CONSENT_KEY);`,
  `    try { localStorage.removeItem(CONSENT_KEY); } catch { /* storage blocked */ }`
);

fs.writeFileSync(path.join(BASE, 'components/CookieConsent.tsx'), cookie, 'utf8');
console.log('3. Fixed CookieConsent localStorage');

// ============================================================
// 4. Fix IntroSplash - wrap sessionStorage in try-catch
// ============================================================
let intro = fs.readFileSync(path.join(BASE, 'components/IntroSplash.tsx'), 'utf8');

intro = intro.replace(
  `    const introSeen = sessionStorage.getItem("kb_intro_seen");`,
  `    let introSeen: string | null = null;
    try { introSeen = sessionStorage.getItem("kb_intro_seen"); } catch { /* storage blocked */ }`
);

intro = intro.replace(
  `        sessionStorage.setItem("kb_intro_seen", "true");`,
  `        try { sessionStorage.setItem("kb_intro_seen", "true"); } catch { /* storage blocked */ }`
);

fs.writeFileSync(path.join(BASE, 'components/IntroSplash.tsx'), intro, 'utf8');
console.log('4. Fixed IntroSplash sessionStorage');

// ============================================================
// 5. Fix UTM code in pricing - wrap in try-catch
// ============================================================
let pricing = fs.readFileSync(path.join(BASE, 'app/pricing/page.tsx'), 'utf8');

pricing = pricing.replace(
  `  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"];
    const pairs = utmKeys
      .filter(k => params.has(k))
      .map(k => k + "=" + encodeURIComponent(params.get(k)!));
    if (pairs.length > 0) setUtmSuffix("&" + pairs.join("&"));
  }, []);`,
  `  useEffect(() => {
    try {
      const params = new URLSearchParams(window.location.search);
      const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"];
      const pairs = utmKeys
        .filter(k => params.has(k))
        .map(k => k + "=" + encodeURIComponent(params.get(k)!));
      if (pairs.length > 0) setUtmSuffix("&" + pairs.join("&"));
    } catch { /* safe fallback - links stay without UTM */ }
  }, []);`
);

fs.writeFileSync(path.join(BASE, 'app/pricing/page.tsx'), pricing, 'utf8');
console.log('5. Fixed pricing UTM try-catch');

// ============================================================
// Verify
// ============================================================
console.log('\n=== VERIFICATION ===');
console.log('global-error.tsx exists:', fs.existsSync(path.join(BASE, 'app/global-error.tsx')));
console.log('error.tsx exists:', fs.existsSync(path.join(BASE, 'app/error.tsx')));
console.log('CookieConsent has try-catch:', fs.readFileSync(path.join(BASE, 'components/CookieConsent.tsx'), 'utf8').includes('try { stored = localStorage'));
console.log('IntroSplash has try-catch:', fs.readFileSync(path.join(BASE, 'components/IntroSplash.tsx'), 'utf8').includes('try { introSeen = sessionStorage'));
console.log('Pricing UTM has try-catch:', fs.readFileSync(path.join(BASE, 'app/pricing/page.tsx'), 'utf8').includes('try {'));
