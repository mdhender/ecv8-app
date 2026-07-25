import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Alert from 'ec/components/ui/alert';

/**
 * The route-level error page.
 *
 * Every failure the API produces is an RFC 9457 Problem Details document, which
 * the API service turns into an ApiError carrying `status` and a message
 * written for a person. The status decides the wording here; the detail is shown
 * as-is because the server already decided what a client may be told.
 */
function heading(error) {
  switch (error?.status) {
    case 401:
      return 'You need to sign in';
    case 403:
      return 'You do not have access to that';
    case 404:
      return 'Not found';
    case 503:
      return 'The service is unavailable';
    default:
      return 'Something went wrong';
  }
}

function isAuthProblem(error) {
  return error?.status === 401;
}

<template>
  {{pageTitle "Error"}}

  <div class="mx-auto max-w-2xl space-y-4">
    <h1 class="text-2xl font-semibold">{{heading @model}}</h1>

    <Alert @kind="error">
      <p>
        {{#if @model.message}}
          {{@model.message}}
        {{else}}
          The page could not be loaded. Try again in a moment.
        {{/if}}
      </p>
    </Alert>

    <p>
      {{#if (isAuthProblem @model)}}
        <LinkTo
          @route="login"
          class="text-brand-700 underline dark:text-brand-200"
        >
          Go to sign in
        </LinkTo>
      {{else}}
        <LinkTo
          @route="dashboard"
          class="text-brand-700 underline dark:text-brand-200"
        >
          Back to the dashboard
        </LinkTo>
      {{/if}}
    </p>
  </div>
</template>
