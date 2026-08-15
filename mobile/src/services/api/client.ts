import { config } from '@/services/config';
import { deleteSecret, readSecret, secureKeys, writeSecret } from '@/services/secure-storage';
import type { ApiErrorBody, AuthResponse } from '@/types/api';

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: Record<string, string[]> | null;

  constructor(status: number, body: ApiErrorBody) {
    super(body.message);
    this.name = 'ApiError';
    this.status = status;
    this.code = body.code;
    this.details = body.details;
  }
}

export class NetworkError extends Error {
  constructor(message = "We couldn't reach MedGuard. Check your connection and try again.") {
    super(message);
    this.name = 'NetworkError';
  }
}

interface Tokens {
  accessToken: string;
  refreshToken: string;
}

let tokens: Tokens | null = null;
let refreshInFlight: Promise<Tokens | null> | null = null;
let onSessionExpired: (() => void) | null = null;

export function setSessionExpiredHandler(handler: (() => void) | null): void {
  onSessionExpired = handler;
}

export function getAccessToken(): string | null {
  return tokens?.accessToken ?? null;
}

export async function loadStoredTokens(): Promise<Tokens | null> {
  const [accessToken, refreshToken] = await Promise.all([
    readSecret(secureKeys.accessToken),
    readSecret(secureKeys.refreshToken),
  ]);

  tokens = accessToken && refreshToken ? { accessToken, refreshToken } : null;
  return tokens;
}

export async function persistTokens(next: Tokens): Promise<void> {
  tokens = next;
  await Promise.all([
    writeSecret(secureKeys.accessToken, next.accessToken),
    writeSecret(secureKeys.refreshToken, next.refreshToken),
  ]);
}

export async function clearTokens(): Promise<void> {
  tokens = null;
  await Promise.all([deleteSecret(secureKeys.accessToken), deleteSecret(secureKeys.refreshToken)]);
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  body?: unknown;
  query?: Record<string, string | number | boolean | null | undefined>;
  /** Endpoints such as sign-in that must not carry (or attempt to refresh) a session. */
  anonymous?: boolean;
  signal?: AbortSignal;
}

function buildUrl(path: string, query?: RequestOptions['query']): string {
  const url = `${config.apiBaseUrl}${path}`;

  if (!query) {
    return url;
  }

  const params = Object.entries(query)
    .filter((entry): entry is [string, string | number | boolean] => entry[1] !== null && entry[1] !== undefined)
    .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);

  return params.length > 0 ? `${url}?${params.join('&')}` : url;
}

async function readErrorBody(response: Response): Promise<ApiErrorBody> {
  try {
    const parsed = (await response.json()) as Partial<ApiErrorBody> & { title?: string };

    if (typeof parsed?.code === 'string' && typeof parsed?.message === 'string') {
      return parsed as ApiErrorBody;
    }

    return {
      code: `http_${response.status}`,
      message: parsed?.title ?? parsed?.message ?? 'Something went wrong. Please try again.',
    };
  } catch {
    return {
      code: `http_${response.status}`,
      message: 'Something went wrong. Please try again.',
    };
  }
}

async function rawFetch(path: string, options: RequestOptions, accessToken: string | null): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), config.requestTimeoutMs);

  const externalAbort = () => controller.abort();
  options.signal?.addEventListener('abort', externalAbort);

  try {
    return await fetch(buildUrl(path, options.query), {
      method: options.method ?? 'GET',
      headers: {
        Accept: 'application/json',
        ...(options.body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      },
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      signal: controller.signal,
    });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError' && !options.signal?.aborted) {
      throw new NetworkError('The request took too long. Please try again.');
    }

    throw error instanceof ApiError ? error : new NetworkError();
  } finally {
    clearTimeout(timeout);
    options.signal?.removeEventListener('abort', externalAbort);
  }
}

/** Refresh runs at most once concurrently; parallel 401s all wait on the same call. */
async function refreshTokens(): Promise<Tokens | null> {
  if (refreshInFlight) {
    return refreshInFlight;
  }

  const currentRefreshToken = tokens?.refreshToken;
  if (!currentRefreshToken) {
    return null;
  }

  refreshInFlight = (async () => {
    try {
      const response = await rawFetch(
        '/api/auth/refresh',
        { method: 'POST', body: { refreshToken: currentRefreshToken } },
        null,
      );

      if (!response.ok) {
        return null;
      }

      const auth = (await response.json()) as AuthResponse;
      const next: Tokens = { accessToken: auth.accessToken, refreshToken: auth.refreshToken };
      await persistTokens(next);
      return next;
    } catch {
      return null;
    } finally {
      refreshInFlight = null;
    }
  })();

  return refreshInFlight;
}

async function parse<T>(response: Response): Promise<T> {
  if (response.status === 204) {
    return undefined as T;
  }

  const text = await response.text();
  return (text.length === 0 ? undefined : JSON.parse(text)) as T;
}

export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const response = await rawFetch(path, options, options.anonymous ? null : getAccessToken());

  if (response.status === 401 && !options.anonymous) {
    const refreshed = await refreshTokens();

    if (!refreshed) {
      await clearTokens();
      onSessionExpired?.();
      throw new ApiError(401, { code: 'session_expired', message: 'Your session ended. Please sign in again.' });
    }

    const retried = await rawFetch(path, options, refreshed.accessToken);

    if (!retried.ok) {
      throw new ApiError(retried.status, await readErrorBody(retried));
    }

    return parse<T>(retried);
  }

  if (!response.ok) {
    throw new ApiError(response.status, await readErrorBody(response));
  }

  return parse<T>(response);
}

export const api = {
  get: <T>(path: string, query?: RequestOptions['query']) => request<T>(path, { method: 'GET', query }),
  post: <T>(path: string, body?: unknown, options?: Omit<RequestOptions, 'method' | 'body'>) =>
    request<T>(path, { ...options, method: 'POST', body }),
  put: <T>(path: string, body?: unknown) => request<T>(path, { method: 'PUT', body }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
};

export function describeError(error: unknown): string {
  if (error instanceof ApiError || error instanceof NetworkError) {
    return error.message;
  }

  return 'Something went wrong. Please try again.';
}
