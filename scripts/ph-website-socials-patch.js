const fs = require('fs');

// =============================================
// PATCH 1: Footer.tsx — Social Links
// =============================================
const footerPath = '/opt/keybuzz/keybuzz-website/src/components/Footer.tsx';
let footer = fs.readFileSync(footerPath, 'utf8');

// 1a. Update import: add Youtube, Linkedin
footer = footer.replace(
  'import { Instagram, Facebook } from "lucide-react";',
  'import { Instagram, Facebook, Youtube, Linkedin } from "lucide-react";'
);

// 1b. Replace the entire social links block
const oldSocialBlock = [
  '            {/* Social Links */}',
  '            <div className="flex gap-3">',
  '              <a',
  '                href="https://www.instagram.com/keybuzz_consulting"',
  '                target="_blank"',
  '                rel="noopener noreferrer"',
  '                className="w-9 h-9 bg-slate-800 hover:bg-[#26a9e0] rounded-lg flex items-center justify-center transition-colors"',
  '                aria-label="Instagram"',
  '              >',
  '                <Instagram className="w-4 h-4" />',
  '              </a>',
  '              <a',
  '                href="#"',
  '                target="_blank"',
  '                rel="noopener noreferrer"',
  '                className="w-9 h-9 bg-slate-800 hover:bg-[#26a9e0] rounded-lg flex items-center justify-center transition-colors"',
  '                aria-label="Facebook"',
  '              >',
  '                <Facebook className="w-4 h-4" />',
  '              </a>',
  '            </div>',
].join('\n');

const socialLink = (href, label, iconJsx) => [
  '              <a',
  `                href="${href}"`,
  '                target="_blank"',
  '                rel="noopener noreferrer"',
  '                className="w-9 h-9 bg-slate-800 hover:bg-[#26a9e0] rounded-lg flex items-center justify-center transition-colors"',
  `                aria-label="${label}"`,
  '              >',
  `                ${iconJsx}`,
  '              </a>',
].join('\n');

const tiktokSvg = '<svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-2.88 2.5 2.89 2.89 0 0 1-2.89-2.89 2.89 2.89 0 0 1 2.89-2.89c.28 0 .54.04.79.1v-3.51a6.37 6.37 0 0 0-.79-.05A6.34 6.34 0 0 0 3.15 15a6.34 6.34 0 0 0 6.34 6.34 6.34 6.34 0 0 0 6.34-6.34V8.75a8.18 8.18 0 0 0 4.76 1.52v-3.4a4.85 4.85 0 0 1-1-.18z"/></svg>';

const newSocialBlock = [
  '            {/* Social Links */}',
  '            <div className="flex flex-wrap gap-3">',
  socialLink('https://www.instagram.com/ludo_keybuzz', 'Instagram', '<Instagram className="w-4 h-4" />'),
  socialLink('https://www.youtube.com/@KeyBuzzConsulting', 'YouTube', '<Youtube className="w-4 h-4" />'),
  socialLink('https://www.tiktok.com/@ludo_keybuzz', 'TikTok', tiktokSvg),
  socialLink('https://www.linkedin.com/in/ludovic-keybuzz', 'LinkedIn', '<Linkedin className="w-4 h-4" />'),
  socialLink('https://www.facebook.com/profile.php?id=61579202964773', 'Facebook', '<Facebook className="w-4 h-4" />'),
  '            </div>',
].join('\n');

if (!footer.includes(oldSocialBlock)) {
  console.error('FOOTER: old social block not found — ABORTING');
  process.exit(1);
}

footer = footer.replace(oldSocialBlock, newSocialBlock);
fs.writeFileSync(footerPath, footer, 'utf8');
console.log('FOOTER: patched OK');

// =============================================
// PATCH 2: contact/page.tsx — Remove phone, update LinkedIn
// =============================================
const contactPath = '/opt/keybuzz/keybuzz-website/src/app/contact/page.tsx';
let contact = fs.readFileSync(contactPath, 'utf8');

// 2a. Remove Phone from import
contact = contact.replace(
  'import { Mail, Phone, Linkedin, Check, Send, Loader2, CheckCircle, AlertCircle } from "lucide-react";',
  'import { Mail, Linkedin, Check, Send, Loader2, CheckCircle, AlertCircle } from "lucide-react";'
);

// 2b. Remove the phone block
const phoneBlock = [
  '',
  '                  <div className="flex items-start gap-4">',
  '                    <FeatureIcon icon={Phone} size="md" variant="light" />',
  '                    <div>',
  '                      <p className="font-medium text-slate-900">Téléphone</p>',
  '                      <a href="tel:+33783348999" className="text-[#26a9e0] hover:underline">',
  '                        +33 7 83 34 89 99',
  '                      </a>',
  '                    </div>',
  '                  </div>',
].join('\n');

if (!contact.includes(phoneBlock)) {
  console.error('CONTACT: phone block not found — ABORTING');
  process.exit(1);
}

contact = contact.replace(phoneBlock, '');

// 2c. Update LinkedIn URL
contact = contact.replace(
  'href="https://www.linkedin.com/company/keybuzz"',
  'href="https://www.linkedin.com/in/ludovic-keybuzz"'
);

// 2d. Update LinkedIn display text
contact = contact.replace(
  'linkedin.com/company/keybuzz',
  'linkedin.com/in/ludovic-keybuzz'
);

fs.writeFileSync(contactPath, contact, 'utf8');
console.log('CONTACT: patched OK');

console.log('ALL PATCHES APPLIED');
