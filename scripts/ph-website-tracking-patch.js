const fs = require('fs');
const path = require('path');

const BASE = '/opt/keybuzz/keybuzz-website/src';

// ============================================================
// 1. Create src/lib/tracking.ts
// ============================================================
const trackingLib = `
type GTagEvent = {
  action: string;
  category?: string;
  label?: string;
  value?: number;
  [key: string]: unknown;
};

export function trackEvent({ action, category, label, value, ...rest }: GTagEvent) {
  if (typeof window === "undefined") return;

  // GA4
  if (typeof window.gtag === "function") {
    window.gtag("event", action, {
      event_category: category,
      event_label: label,
      value,
      ...rest,
    });
  }

  // Meta Pixel
  if (typeof window.fbq === "function") {
    window.fbq("trackCustom", action, {
      category,
      label,
      value,
      ...rest,
    });
  }
}

export function trackViewPricing() {
  trackEvent({ action: "view_pricing", category: "engagement" });
  if (typeof window !== "undefined" && typeof window.fbq === "function") {
    window.fbq("track", "ViewContent", { content_name: "pricing" });
  }
}

export function trackSelectPlan(plan: string, cycle: string) {
  trackEvent({ action: "select_plan", category: "conversion", label: plan, plan, cycle });
  if (typeof window !== "undefined" && typeof window.fbq === "function") {
    window.fbq("track", "InitiateCheckout", { content_name: plan, currency: "EUR" });
  }
}

export function trackClickSignup(plan: string) {
  trackEvent({ action: "click_signup", category: "conversion", label: plan });
  if (typeof window !== "undefined" && typeof window.fbq === "function") {
    window.fbq("track", "Lead", { content_name: plan });
  }
}

export function trackContactSubmit() {
  trackEvent({ action: "contact_submit", category: "conversion" });
  if (typeof window !== "undefined" && typeof window.fbq === "function") {
    window.fbq("track", "Contact");
  }
}

declare global {
  interface Window {
    gtag: (...args: unknown[]) => void;
    fbq: (...args: unknown[]) => void;
    dataLayer: unknown[];
  }
}
`.trimStart();

fs.writeFileSync(path.join(BASE, 'lib/tracking.ts'), trackingLib, 'utf8');
console.log('1. Created lib/tracking.ts');

// ============================================================
// 2. Create src/components/Analytics.tsx (client component)
// ============================================================
const analyticsComponent = `"use client";

import Script from "next/script";
import { usePathname } from "next/navigation";
import { useEffect } from "react";

const GA_ID = process.env.NEXT_PUBLIC_GA_ID;
const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;

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

  return (
    <>
      {GA_ID && (
        <>
          <Script
            src={\`https://www.googletagmanager.com/gtag/js?id=\${GA_ID}\`}
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
              gtag('config', '\${GA_ID}', {
                linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
              });
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
`.trimStart();

fs.writeFileSync(path.join(BASE, 'components/Analytics.tsx'), analyticsComponent, 'utf8');
console.log('2. Created components/Analytics.tsx');

// ============================================================
// 3. Update layout.tsx — add Analytics component
// ============================================================
let layout = fs.readFileSync(path.join(BASE, 'app/layout.tsx'), 'utf8');

if (!layout.includes('Analytics')) {
  layout = layout.replace(
    'import { CookieConsent } from "@/components/CookieConsent";',
    'import { CookieConsent } from "@/components/CookieConsent";\nimport Analytics from "@/components/Analytics";'
  );

  layout = layout.replace(
    '<MotionDebugBadge />',
    '<MotionDebugBadge />\n        <Analytics />'
  );

  fs.writeFileSync(path.join(BASE, 'app/layout.tsx'), layout, 'utf8');
  console.log('3. Updated layout.tsx with Analytics');
} else {
  console.log('3. layout.tsx already has Analytics (skipped)');
}

// ============================================================
// 4. Update pricing/page.tsx — add tracking events
// ============================================================
let pricing = fs.readFileSync(path.join(BASE, 'app/pricing/page.tsx'), 'utf8');

if (!pricing.includes('trackViewPricing')) {
  // Add import
  pricing = pricing.replace(
    'import Reveal, { MotionDebugBadge } from "@/components/Reveal";',
    'import Reveal, { MotionDebugBadge } from "@/components/Reveal";\nimport { trackViewPricing, trackSelectPlan, trackClickSignup } from "@/lib/tracking";'
  );

  // Add view_pricing event in useEffect (after UTM effect)
  pricing = pricing.replace(
    '  const [openSections, setOpenSections]',
    '  useEffect(() => { trackViewPricing(); }, []);\n\n  const [openSections, setOpenSections]'
  );

  // Add click tracking on CTA href
  pricing = pricing.replace(
    "href={plan.ctaLink.replace('cycle=monthly', `cycle=${isAnnual ? 'yearly' : 'monthly'}`) + utmSuffix}",
    "href={plan.ctaLink.replace('cycle=monthly', `cycle=${isAnnual ? 'yearly' : 'monthly'}`) + utmSuffix}\n                    onClick={() => { trackSelectPlan(plan.id, isAnnual ? 'yearly' : 'monthly'); trackClickSignup(plan.id); }}"
  );

  fs.writeFileSync(path.join(BASE, 'app/pricing/page.tsx'), pricing, 'utf8');
  console.log('4. Updated pricing/page.tsx with tracking events');
} else {
  console.log('4. pricing/page.tsx already has tracking (skipped)');
}

// ============================================================
// 5. Update contact/page.tsx — add contact_submit tracking
// ============================================================
let contact = fs.readFileSync(path.join(BASE, 'app/contact/page.tsx'), 'utf8');

if (!contact.includes('trackContactSubmit')) {
  // Add import
  contact = contact.replace(
    'import { useState } from "react";',
    'import { useState } from "react";\nimport { trackContactSubmit } from "@/lib/tracking";'
  );

  // Add tracking call after success
  contact = contact.replace(
    '        setStatus("success");',
    '        setStatus("success");\n        trackContactSubmit();'
  );

  fs.writeFileSync(path.join(BASE, 'app/contact/page.tsx'), contact, 'utf8');
  console.log('5. Updated contact/page.tsx with contact_submit tracking');
} else {
  console.log('5. contact/page.tsx already has tracking (skipped)');
}

// ============================================================
// 6. Update pricing UTM to also capture gclid/fbclid
// ============================================================
if (pricing.includes('"utm_content"]') && !pricing.includes('gclid')) {
  let pricingUpdated = fs.readFileSync(path.join(BASE, 'app/pricing/page.tsx'), 'utf8');
  pricingUpdated = pricingUpdated.replace(
    '["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"]',
    '["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid"]'
  );
  fs.writeFileSync(path.join(BASE, 'app/pricing/page.tsx'), pricingUpdated, 'utf8');
  console.log('6. Extended UTM forwarding with gclid/fbclid');
} else {
  console.log('6. gclid/fbclid already present or skipped');
}

// ============================================================
// 7. Update Dockerfile — add GA/Meta build args
// ============================================================
let dockerfile = fs.readFileSync('/opt/keybuzz/keybuzz-website/Dockerfile', 'utf8');

if (!dockerfile.includes('NEXT_PUBLIC_GA_ID')) {
  dockerfile = dockerfile.replace(
    'ARG NEXT_PUBLIC_CLIENT_APP_URL\nENV NEXT_PUBLIC_SITE_MODE=${NEXT_PUBLIC_SITE_MODE}\nENV NEXT_PUBLIC_CLIENT_APP_URL=${NEXT_PUBLIC_CLIENT_APP_URL}',
    'ARG NEXT_PUBLIC_CLIENT_APP_URL\nARG NEXT_PUBLIC_GA_ID\nARG NEXT_PUBLIC_META_PIXEL_ID\nENV NEXT_PUBLIC_SITE_MODE=${NEXT_PUBLIC_SITE_MODE}\nENV NEXT_PUBLIC_CLIENT_APP_URL=${NEXT_PUBLIC_CLIENT_APP_URL}\nENV NEXT_PUBLIC_GA_ID=${NEXT_PUBLIC_GA_ID}\nENV NEXT_PUBLIC_META_PIXEL_ID=${NEXT_PUBLIC_META_PIXEL_ID}'
  );
  fs.writeFileSync('/opt/keybuzz/keybuzz-website/Dockerfile', dockerfile, 'utf8');
  console.log('7. Updated Dockerfile with GA/Meta build args');
} else {
  console.log('7. Dockerfile already has GA/Meta args (skipped)');
}

// ============================================================
// Verify
// ============================================================
console.log('\n=== VERIFICATION ===');
console.log('tracking.ts exists:', fs.existsSync(path.join(BASE, 'lib/tracking.ts')));
console.log('Analytics.tsx exists:', fs.existsSync(path.join(BASE, 'components/Analytics.tsx')));
const layoutCheck = fs.readFileSync(path.join(BASE, 'app/layout.tsx'), 'utf8');
console.log('layout has Analytics:', layoutCheck.includes('Analytics'));
const pricingCheck = fs.readFileSync(path.join(BASE, 'app/pricing/page.tsx'), 'utf8');
console.log('pricing has trackViewPricing:', pricingCheck.includes('trackViewPricing'));
console.log('pricing has gclid:', pricingCheck.includes('gclid'));
const contactCheck = fs.readFileSync(path.join(BASE, 'app/contact/page.tsx'), 'utf8');
console.log('contact has trackContactSubmit:', contactCheck.includes('trackContactSubmit'));
const dockerCheck = fs.readFileSync('/opt/keybuzz/keybuzz-website/Dockerfile', 'utf8');
console.log('Dockerfile has GA_ID:', dockerCheck.includes('NEXT_PUBLIC_GA_ID'));
