/**
 * Formatting helpers shared by templates.
 *
 * Dates arrive from the API as RFC 3339 UTC strings. They are rendered in the
 * viewer's own locale and time zone, because a timestamp is only useful if the
 * reader can place it without doing arithmetic.
 */

const DATE_TIME = new Intl.DateTimeFormat(undefined, {
  dateStyle: 'medium',
  timeStyle: 'short',
});

/** Renders an API timestamp for display, or an em dash when absent. */
export function formatDateTime(value) {
  if (!value) {
    return '—';
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }
  return DATE_TIME.format(date);
}
