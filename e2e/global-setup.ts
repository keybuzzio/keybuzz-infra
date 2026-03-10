// PH-S03.5E: Mask sensitive values in logs (cookie values, tokens)
export default function globalSetup() {
  // No-op; masking is done in workflow when uploading artifacts
}

export function maskSecret(s: string): string {
  if (!s || s.length < 8) return '***';
  return s.slice(0, 2) + '***' + s.slice(-2);
}
