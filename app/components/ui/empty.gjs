/** Empty explains why a list has nothing in it, instead of showing blank space. */
<template>
  <div
    class="rounded-md border border-dashed border-slate-300 p-8 text-center dark:border-slate-600"
  >
    <p class="font-medium text-slate-700 dark:text-slate-200">{{@title}}</p>
    {{#if (has-block)}}
      <div
        class="mt-1 text-sm text-slate-500 dark:text-slate-400"
      >{{yield}}</div>
    {{/if}}
  </div>
</template>
