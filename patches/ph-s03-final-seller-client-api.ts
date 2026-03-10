/**
 * PH-S01: API client pour seller-api
 * PH-S03.3A / PH-S03.5: messages explicites (plus de "Unknown error")
 * PH-S03.5B: status et endpoint sur l'Error
 * Gere l'authentification via headers X-User-Email et X-Tenant-Id
 */

import { config } from './config';

// Store pour les headers d'auth (set par AuthProvider)
let userEmail: string | null = null;
let tenantId: string | null = null;

export function setAuthHeaders(email: string | null, tenant: string | null) {
  userEmail = email;
  tenantId = tenant;
}

export function getAuthHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  
  if (userEmail) {
    headers['X-User-Email'] = userEmail;
  }
  
  if (tenantId) {
    headers['X-Tenant-Id'] = tenantId;
  }
  
  return headers;
}

interface ApiOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  headers?: Record<string, string>;
}

export async function apiCall<T>(
  endpoint: string,
  options: ApiOptions = {}
): Promise<T> {
  const { method = 'GET', body, headers = {} } = options;
  
  // PH-S03.1: en navigateur, forcer le proxy same-origin (jamais d'appel direct à l'API)
  const base = typeof window !== 'undefined' ? '' : (config.apiUrl || '');
  const path = base ? `${base}${endpoint}` : `${config.apiProxyPrefix}${endpoint}`;
  const url = path.startsWith('http') ? path : (typeof window !== 'undefined' ? `${window.location.origin}${path}` : `${config.clientUrl}${path}`);
  
  let response: Response;
  try {
    response = await fetch(url, {
      method,
      headers: {
        ...getAuthHeaders(),
        ...headers,
      },
      body: body ? JSON.stringify(body) : undefined,
      credentials: 'include',
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg === 'Failed to fetch' || msg.includes('fetch')) {
      throw new Error(
        'Impossible de joindre le serveur. Vérifiez votre connexion ou réessayez plus tard.'
      );
    }
    throw err;
  }
  
  if (!response.ok) {
    if (response.status === 401) {
      // Rediriger vers login KeyBuzz
      const returnTo = encodeURIComponent(window.location.href);
      window.location.href = `${config.sso.loginUrl}?returnTo=${returnTo}`;
      const e = new Error('Connexion expirée, merci de vous reconnecter.');
      (e as Error & { status?: number; endpoint?: string }).status = 401;
      (e as Error & { status?: number; endpoint?: string }).endpoint = endpoint;
      throw e;
    }

    // PH-S03.3A / PH-S03.5: messages explicites (plus de "Unknown error")
    const fallbackMessage = (status: number): string => {
      if (status === 401) return 'Connexion expirée, reconnectez-vous.';
      if (status === 403) return 'Accès refusé.';
      if (status === 404) return 'Ressource introuvable.';
      if (status === 422) return 'Champs invalides.';
      if (status >= 500) return 'Erreur serveur, réessayez.';
      return `Erreur ${status}.`;
    };

    const error = await response.json().catch(() => {
      if (typeof window !== 'undefined') {
        console.warn('[api]', response.status, endpoint, '(réponse non JSON)');
      }
      return { detail: fallbackMessage(response.status) };
    });

    if (typeof window !== 'undefined' && response.status >= 400) {
      console.warn('[api]', response.status, endpoint);
    }

    // Extraire le message d'erreur — PH-S03.5: remplacer "Unknown error" par message explicite
    let errorMessage: string;
    if (typeof error.detail === 'string') {
      const raw = error.detail;
      const isGeneric = !raw || /^unknown\s*error$/i.test(raw) || /^auth\s*error$/i.test(raw);
      errorMessage = isGeneric ? fallbackMessage(response.status) : raw;
    } else if (Array.isArray(error.detail)) {
      // FastAPI 422 validation errors: [{loc: [...], msg: "...", type: "..."}]
      errorMessage = error.detail.map((e: { msg?: string; loc?: string[] }) => {
        const loc = e.loc?.filter((x: string) => x !== 'body').join('.') || '';
        return loc ? `${loc}: ${e.msg || 'Validation error'}` : (e.msg || 'Validation error');
      }).join(' ; ');
    } else if (error.detail && typeof error.detail === 'object') {
      errorMessage = JSON.stringify(error.detail);
    } else if (error.message) {
      const raw = error.message;
      const isGeneric = !raw || /^unknown\s*error$/i.test(raw) || /^auth\s*error$/i.test(raw);
      errorMessage = isGeneric ? fallbackMessage(response.status) : raw;
    } else {
      errorMessage = fallbackMessage(response.status);
    }

    const e = new Error(errorMessage);
    (e as Error & { status?: number; endpoint?: string }).status = response.status;
    (e as Error & { status?: number; endpoint?: string }).endpoint = endpoint;
    throw e;
  }
  
  // Handle 204 No Content
  if (response.status === 204) {
    return undefined as T;
  }
  
  try {
    return await response.json();
  } catch {
    throw new Error('Réponse serveur invalide (non JSON)');
  }
}

/**
 * PH-S03.5: Message d'erreur explicite pour l'UI (plus de "Unknown error" global).
 * À utiliser partout où on affiche err.message (setError(getDisplayErrorMessage(err))).
 */
export function getDisplayErrorMessage(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err ?? '');
  if (!msg || /^unknown\s*error$/i.test(msg) || /^auth\s*error$/i.test(msg)) {
    return 'Erreur inattendue. Réessayez ou reconnectez-vous.';
  }
  if (/failed\s*to\s*fetch|impossible\s*de\s*joindre|connexion|réseau/i.test(msg)) {
    return 'Erreur réseau. Vérifiez votre connexion.';
  }
  if (/connexion\s*expirée|reconnectez/i.test(msg)) return msg;
  if (/accès\s*refusé/i.test(msg)) return msg;
  if (/ressource\s*introuvable|not\s*found/i.test(msg)) return 'Ressource introuvable.';
  if (/erreur\s*serveur|réessayez/i.test(msg)) return msg;
  if (/champs\s*invalides|validation/i.test(msg)) return msg;
  return msg;
}

// Helpers
export const api = {
  get: <T>(endpoint: string) => apiCall<T>(endpoint, { method: 'GET' }),
  post: <T>(endpoint: string, body: unknown) => apiCall<T>(endpoint, { method: 'POST', body }),
  put: <T>(endpoint: string, body: unknown) => apiCall<T>(endpoint, { method: 'PUT', body }),
  patch: <T>(endpoint: string, body: unknown) => apiCall<T>(endpoint, { method: 'PATCH', body }),
  delete: (endpoint: string) => apiCall<void>(endpoint, { method: 'DELETE' }),
};
