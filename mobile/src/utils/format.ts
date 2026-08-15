export function greeting(date = new Date()): string {
  const hour = date.getHours();

  if (hour < 12) {
    return 'Good morning';
  }

  if (hour < 18) {
    return 'Good afternoon';
  }

  return 'Good evening';
}

export function formatDate(value: string | Date): string {
  const date = typeof value === 'string' ? parseDateLike(value) : value;

  return date.toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'short' });
}

export function formatDateTime(value: string): string {
  const date = parseDateLike(value);

  return `${date.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })}, ${formatTime(date)}`;
}

export function formatTime(value: string | Date): string {
  const date = typeof value === 'string' ? parseDateLike(value) : value;

  return date.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
}

/** Backend `DateOnly` values arrive as `yyyy-MM-dd` and must not shift across time zones. */
function parseDateLike(value: string): Date {
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const [year, month, day] = value.split('-').map(Number);
    return new Date(year ?? 1970, (month ?? 1) - 1, day ?? 1);
  }

  return new Date(value);
}

export function formatConfidence(confidence: number): string {
  return `${Math.round(confidence * 100)}%`;
}

export function isToday(value: string): boolean {
  const date = parseDateLike(value);
  const now = new Date();

  return (
    date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() && date.getDate() === now.getDate()
  );
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join('');
}
