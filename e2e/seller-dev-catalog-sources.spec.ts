// PH-S03.5E: Validation par navigateur headless — Catalog Sources + Wizard FTP
// Critères: pas de bandeau "Unknown error", wizard 5 étapes max, pas "Mapping des colonnes"
import { test, expect } from '@playwright/test';

const SELLER_DEV_URL = process.env.SELLER_DEV_URL || 'https://seller-dev.keybuzz.io';
const CLIENT_DEV_URL = process.env.CLIENT_DEV_URL || 'https://client-dev.keybuzz.io';

test.describe('PH-S03.5E seller-dev Catalog Sources', () => {
  test.beforeEach(async ({ page }) => {
    // Inject session cookies if provided (secret SELLER_DEV_COOKIES = JSON array)
    const cookiesJson = process.env.SELLER_DEV_COOKIES;
    if (cookiesJson) {
      try {
        const cookies = JSON.parse(cookiesJson) as Array<{ name: string; value: string; domain?: string; path?: string }>;
        await page.context().addCookies(
          cookies.map((c) => ({
            name: c.name,
            value: c.value,
            domain: c.domain || '.keybuzz.io',
            path: c.path || '/',
          }))
        );
      } catch {
        // Invalid JSON: skip cookie injection
      }
    }
  });

  test('Catalog Sources: no "Unknown error" banner (with session)', async ({ page }) => {
    await page.goto(`${SELLER_DEV_URL}/catalog-sources`, { waitUntil: 'networkidle', timeout: 15000 });
    // If not authenticated we get redirect to login
    const url = page.url();
    if (url.includes('/login') || url.includes('client-dev')) {
      test.skip();
      return;
    }
    // Check DOM: no visible "Unknown error" banner
    const body = await page.locator('body').textContent();
    const hasUnknownError = body?.includes('Unknown error') ?? false;
    expect(hasUnknownError, 'Page must not show "Unknown error"').toBe(false);
    await page.screenshot({ path: 'test-results/catalog-sources-page.png', fullPage: true });
  });

  test('Wizard FTP: 5 steps max, no "Mapping des colonnes" (with session)', async ({ page }) => {
    await page.goto(`${SELLER_DEV_URL}/catalog-sources`, { waitUntil: 'networkidle', timeout: 15000 });
    const url = page.url();
    if (url.includes('/login') || url.includes('client-dev')) {
      test.skip();
      return;
    }
    // Click "Ajouter une source"
    await page.getByRole('button', { name: /Ajouter une source/i }).click();
    await page.waitForTimeout(500);
    // Select FTP CSV path: Kind = supplier, Type = Fichier CSV
    await page.getByRole('button', { name: /Fournisseur/i }).first().click();
    await page.waitForTimeout(300);
    await page.getByRole('button', { name: /Fichier CSV/i }).first().click();
    await page.waitForTimeout(300);
    // Stepper: "Etape X sur Y" — Y must be 5 for FTP (not 6)
    const stepper = page.getByText(/Etape\s+\d+\s+sur\s+\d+/).first();
    await expect(stepper).toBeVisible({ timeout: 5000 });
    const stepText = await stepper.textContent();
    const match = stepText?.match(/Etape\s+(\d+)\s+sur\s+(\d+)/);
    const totalSteps = match ? parseInt(match[2], 10) : 0;
    expect(totalSteps, 'Wizard must have 5 steps (FTP), not 6').toBe(5);
    // No "Mapping des colonnes" in wizard
    const wizardBody = await page.locator('[class*="modal"], [role="dialog"], .fixed').first().textContent();
    const hasMappingStep = wizardBody?.includes('Mapping des colonnes') ?? false;
    expect(hasMappingStep, 'Wizard must not show "Mapping des colonnes"').toBe(false);
    await page.screenshot({ path: 'test-results/wizard-stepper.png', fullPage: false });
  });

  test('Without session: redirect or no Unknown error in initial HTML', async ({ page }) => {
    await page.goto(`${SELLER_DEV_URL}/catalog-sources`, { waitUntil: 'domcontentloaded', timeout: 10000 });
    const html = await page.content();
    const hasUnknownError = html.includes('Unknown error');
    expect(hasUnknownError, 'Initial HTML must not contain "Unknown error"').toBe(false);
  });
});
