/**
 * Alert renders a status message.
 *
 * `@kind` is one of error, success, warning, or info. Errors and warnings use
 * role="alert" so a screen reader announces them as soon as they appear, which
 * is what a form validation failure needs; quieter kinds use role="status" so
 * they do not interrupt.
 */
const STYLES = {
  error:
    'bg-red-50 text-red-900 border-red-300 dark:bg-red-950 dark:text-red-100 dark:border-red-800',
  success:
    'bg-green-50 text-green-900 border-green-300 dark:bg-green-950 dark:text-green-100 dark:border-green-800',
  warning:
    'bg-amber-50 text-amber-900 border-amber-300 dark:bg-amber-950 dark:text-amber-100 dark:border-amber-800',
  info: 'bg-brand-50 text-brand-900 border-brand-200 dark:bg-slate-800 dark:text-slate-100 dark:border-slate-700',
};

function classes(kind) {
  return `rounded-md border px-4 py-3 text-sm ${STYLES[kind] ?? STYLES.info}`;
}

function liveRole(kind) {
  return kind === 'error' || kind === 'warning' ? 'alert' : 'status';
}

<template>
  <div class={{classes @kind}} role={{liveRole @kind}}>
    {{#if @title}}
      <p class="font-semibold">{{@title}}</p>
    {{/if}}
    {{yield}}
  </div>
</template>
