const fs = require('fs');

const ANALYTICS_PATH = '/opt/keybuzz/keybuzz-website/src/components/Analytics.tsx';
const DOCKERFILE_PATH = '/opt/keybuzz/keybuzz-website/Dockerfile';

// ============================================================
// 1. Patch Analytics.tsx — add sGTM routing
// ============================================================
let analytics = fs.readFileSync(ANALYTICS_PATH, 'utf8');

if (analytics.includes('SGTM_URL')) {
  console.log('1. Analytics.tsx already has SGTM_URL (skipped)');
} else {
  // Add SGTM_URL const
  analytics = analytics.replace(
    'const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;',
    'const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;\nconst SGTM_URL = process.env.NEXT_PUBLIC_SGTM_URL || "";'
  );

  // Replace gtag.js script src — conditional sGTM
  analytics = analytics.replace(
    "src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`}",
    "src={SGTM_URL ? `${SGTM_URL}/gtag/js?id=${GA_ID}` : `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`}"
  );

  // Add server_container_url to gtag config
  analytics = analytics.replace(
    "gtag('config', '${GA_ID}', {\n                linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }\n              });",
    "gtag('config', '${GA_ID}', {\n                ${SGTM_URL ? `server_container_url: '${SGTM_URL}',` : ''}\n                linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }\n              });"
  );

  fs.writeFileSync(ANALYTICS_PATH, analytics, 'utf8');
  console.log('1. Patched Analytics.tsx with sGTM routing');
}

// Verify the inline script approach won't work because template literals
// inside template literals are tricky. Let me write the full correct file instead.

// ============================================================
// 1b. Write correct Analytics.tsx
// ============================================================
const correctAnalytics = `"use client";

import Script from "next/script";
import { usePathname } from "next/navigation";
import { useEffect } from "react";

const GA_ID = process.env.NEXT_PUBLIC_GA_ID;
const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;
const SGTM_URL = process.env.NEXT_PUBLIC_SGTM_URL || "";

export default function Analytics() {
  const pathname = usePathname();

  useEffect(() => {
    if (!GA_ID || typeof window.gtag !== "function") return;
    window.gtag("config", GA_ID, { page_path: pathname });
  }, [pathname]);

  useEffect(() => {
    if (!META_PIXEL_ID || typeof window.fbq !== "function") return;
    window.fbq("track", "PageView");
  }, [pathname]);

  if (!GA_ID && !META_PIXEL_ID) return null;

  const gtagSrc = SGTM_URL
    ? \`\${SGTM_URL}/gtag/js?id=\${GA_ID}\`
    : \`https://www.googletagmanager.com/gtag/js?id=\${GA_ID}\`;

  const gtagConfig = SGTM_URL
    ? \`
              gtag('config', '\${GA_ID}', {
                server_container_url: '\${SGTM_URL}',
                linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
              });
            \`
    : \`
              gtag('config', '\${GA_ID}', {
                linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
              });
            \`;

  return (
    <>
      {GA_ID && (
        <>
          <Script
            src={gtagSrc}
            strategy="afterInteractive"
          />
          <Script id="gtag-init" strategy="afterInteractive">
            {\`
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('consent', 'default', {
                analytics_storage: 'granted',
                ad_storage: 'denied',
                ad_user_data: 'denied',
                ad_personalization: 'denied'
              });
              \${gtagConfig}
            \`}
          </Script>
        </>
      )}
      {META_PIXEL_ID && (
        <Script id="meta-pixel" strategy="afterInteractive">
          {\`
            !function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
            if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
            n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];
            s.parentNode.insertBefore(t,s)}(window, document,'script',
            'https://connect.facebook.net/en_US/fbevents.js');
            fbq('init', '\${META_PIXEL_ID}');
            fbq('track', 'PageView');
          \`}
        </Script>
      )}
    </>
  );
}
`;

fs.writeFileSync(ANALYTICS_PATH, correctAnalytics, 'utf8');
console.log('1b. Wrote correct Analytics.tsx with sGTM conditional routing');

// ============================================================
// 2. Patch Dockerfile — add NEXT_PUBLIC_SGTM_URL build arg
// ============================================================
let dockerfile = fs.readFileSync(DOCKERFILE_PATH, 'utf8');

if (dockerfile.includes('NEXT_PUBLIC_SGTM_URL')) {
  console.log('2. Dockerfile already has SGTM_URL (skipped)');
} else {
  dockerfile = dockerfile.replace(
    'ARG NEXT_PUBLIC_META_PIXEL_ID',
    'ARG NEXT_PUBLIC_META_PIXEL_ID\nARG NEXT_PUBLIC_SGTM_URL='
  );
  dockerfile = dockerfile.replace(
    'ENV NEXT_PUBLIC_META_PIXEL_ID=${NEXT_PUBLIC_META_PIXEL_ID}',
    'ENV NEXT_PUBLIC_META_PIXEL_ID=${NEXT_PUBLIC_META_PIXEL_ID}\nENV NEXT_PUBLIC_SGTM_URL=${NEXT_PUBLIC_SGTM_URL}'
  );
  fs.writeFileSync(DOCKERFILE_PATH, dockerfile, 'utf8');
  console.log('2. Patched Dockerfile with NEXT_PUBLIC_SGTM_URL');
}

// ============================================================
// 3. Verify
// ============================================================
console.log('\n=== VERIFICATION ===');
const a = fs.readFileSync(ANALYTICS_PATH, 'utf8');
console.log('Analytics has SGTM_URL:', a.includes('SGTM_URL'));
console.log('Analytics has server_container_url:', a.includes('server_container_url'));
console.log('Analytics has fallback googletagmanager:', a.includes('googletagmanager.com'));
console.log('Meta Pixel unchanged:', a.includes('fbevents.js'));

const d = fs.readFileSync(DOCKERFILE_PATH, 'utf8');
console.log('Dockerfile has SGTM_URL ARG:', d.includes('ARG NEXT_PUBLIC_SGTM_URL'));
console.log('Dockerfile has SGTM_URL ENV:', d.includes('ENV NEXT_PUBLIC_SGTM_URL'));
