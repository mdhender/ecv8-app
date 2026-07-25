import { LinkTo } from '@ember/routing';

/**
 * Pager renders previous/next links for a list route.
 *
 * The page lives in the URL, so paging is a normal navigation: it can be
 * bookmarked, shared, and reversed with the back button. `@query` carries the
 * route's other filters so paging does not silently drop them.
 */
function previousQuery(meta, query) {
  return { ...query, page: Math.max(1, (meta?.page ?? 1) - 1) };
}

function nextQuery(meta, query) {
  return { ...query, page: (meta?.page ?? 1) + 1 };
}

function hasPrevious(meta) {
  return (meta?.page ?? 1) > 1;
}

function hasNext(meta) {
  return (meta?.page ?? 1) < (meta?.total_pages ?? 1);
}

const LINK =
  'rounded-md border border-slate-300 px-3 py-1.5 text-sm hover:bg-slate-100 dark:border-slate-600 dark:hover:bg-slate-700';
const DISABLED =
  'rounded-md border border-slate-200 px-3 py-1.5 text-sm text-slate-400 dark:border-slate-700 dark:text-slate-600';

<template>
  {{#if @meta}}
    <nav
      class="flex items-center justify-between gap-4 pt-4"
      aria-label="Pagination"
    >
      <p class="text-sm text-slate-600 dark:text-slate-300">
        Page
        {{@meta.page}}
        of
        {{@meta.total_pages}}
        &middot;
        {{@meta.total}}
        total
      </p>

      <div class="flex gap-2">
        {{#if (hasPrevious @meta)}}
          <LinkTo
            @route={{@route}}
            @query={{previousQuery @meta @query}}
            class={{LINK}}
          >
            Previous
          </LinkTo>
        {{else}}
          <span class={{DISABLED}}>Previous</span>
        {{/if}}

        {{#if (hasNext @meta)}}
          <LinkTo
            @route={{@route}}
            @query={{nextQuery @meta @query}}
            class={{LINK}}
          >
            Next
          </LinkTo>
        {{else}}
          <span class={{DISABLED}}>Next</span>
        {{/if}}
      </div>
    </nav>
  {{/if}}
</template>
