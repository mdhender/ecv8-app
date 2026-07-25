import { hash } from '@ember/helper';

/**
 * Field pairs a label with a form control and its validation message.
 *
 * The label's `for` and the control's `id` are wired from `@name`, and the
 * error message is linked with aria-describedby, so a screen reader reads the
 * problem along with the field instead of leaving it stranded on screen.
 * aria-invalid marks the control itself as failing.
 */
function describedBy(name, error) {
  return error ? `${name}-error` : undefined;
}

function errorId(name) {
  return `${name}-error`;
}

<template>
  <div class="space-y-1">
    <label
      for={{@name}}
      class="block text-sm font-medium text-slate-700 dark:text-slate-200"
    >
      {{@label}}
      {{#if @required}}
        <span class="text-red-600" aria-hidden="true">*</span>
      {{/if}}
    </label>

    {{yield
      (hash
        id=@name
        describedBy=(describedBy @name @error)
        invalid=(if @error "true")
      )
    }}

    {{#if @hint}}
      <p class="text-xs text-slate-500 dark:text-slate-400">{{@hint}}</p>
    {{/if}}
    {{#if @error}}
      <p id={{errorId @name}} class="text-sm text-red-700 dark:text-red-300">
        {{@error}}
      </p>
    {{/if}}
  </div>
</template>
