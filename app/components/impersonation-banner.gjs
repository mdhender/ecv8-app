import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { ApiError } from 'ec/services/api';

/**
 * ImpersonationBanner is the unmistakable reminder that an administrator is
 * acting as someone else, and the way back out.
 *
 * It renders nothing when no impersonation is active. While active it is
 * deliberately loud: an administrator who forgets they are impersonating can
 * misread everything else on the page.
 */
export default class ImpersonationBanner extends Component {
  @service api;
  @service session;
  @service router;

  @tracked error = null;
  @tracked isStopping = false;

  stop = async () => {
    this.isStopping = true;
    this.error = null;
    try {
      await this.api.delete('/session/impersonation');
      // Re-read the session before refreshing routes: the identity has changed,
      // and any route reloaded first would be fetched as the wrong account.
      await this.session.refresh();
      this.router.refresh();
    } catch (error) {
      this.error =
        error instanceof ApiError
          ? error.message
          : 'Could not stop impersonating.';
    } finally {
      this.isStopping = false;
    }
  };

  <template>
    {{#if this.session.isImpersonating}}
      <div
        class="border-b border-amber-300 bg-amber-100 dark:border-amber-700 dark:bg-amber-900"
        role="status"
      >
        <div
          class="mx-auto flex max-w-6xl flex-wrap items-center gap-3 px-4 py-2 text-sm text-amber-900 dark:text-amber-100"
        >
          <span>
            You are impersonating
            <strong>{{this.session.account.email}}</strong>
            as
            <strong>{{this.session.impersonator.email}}</strong>. Administrator
            features are unavailable until you stop.
          </span>

          <button
            type="button"
            class="ml-auto rounded-md bg-amber-800 px-3 py-1.5 font-medium text-white hover:bg-amber-900 disabled:opacity-60"
            disabled={{this.isStopping}}
            {{on "click" this.stop}}
          >
            {{if this.isStopping "Stopping…" "Stop impersonating"}}
          </button>

          {{#if this.error}}
            <p class="w-full text-red-800 dark:text-red-200">{{this.error}}</p>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
