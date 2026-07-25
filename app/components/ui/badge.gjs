/**
 * Badge is a small status pill.
 *
 * The label carries the meaning, not the colour, so the state is still legible
 * to someone who cannot distinguish the two shades.
 */
function classes(tone) {
  const base =
    'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium';
  const tones = {
    on: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100',
    off: 'bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-200',
    warn: 'bg-amber-100 text-amber-900 dark:bg-amber-900 dark:text-amber-100',
    info: 'bg-brand-100 text-brand-900 dark:bg-brand-900 dark:text-brand-100',
  };
  return `${base} ${tones[tone] ?? tones.off}`;
}

<template>
  <span class={{classes @tone}}>{{yield}}</span>
</template>
