import Component from '@glimmer/component';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';

/**
 * AppNav is the primary navigation bar.
 *
 * Admin links are hidden from non-administrators, which is a courtesy, not a
 * control: the server authorises every request, so hiding a link only keeps the
 * interface honest about what the current account can do.
 */
export default class AppNav extends Component {
  @service session;
  @service router;

  get showAdmin() {
    return this.session.isAdmin;
  }

  signOut = (event) => {
    event.preventDefault();
    this.session.invalidate();
  };

  <template>
    <header
      class="border-b border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
    >
      <nav
        class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3"
        aria-label="Primary"
      >
        <LinkTo
          @route="dashboard"
          class="text-lg font-semibold text-brand-700 dark:text-brand-200"
        >
          ECV8
        </LinkTo>

        {{#if this.session.isAuthenticated}}
          <LinkTo
            @route="dashboard"
            class="text-sm text-slate-700 hover:underline dark:text-slate-200"
          >
            Dashboard
          </LinkTo>
          <LinkTo
            @route="games"
            class="text-sm text-slate-700 hover:underline dark:text-slate-200"
          >
            Games
          </LinkTo>
          <LinkTo
            @route="profile"
            class="text-sm text-slate-700 hover:underline dark:text-slate-200"
          >
            Profile
          </LinkTo>

          {{#if this.showAdmin}}
            <LinkTo
              @route="admin"
              class="text-sm text-slate-700 hover:underline dark:text-slate-200"
            >
              Administration
            </LinkTo>
          {{/if}}

          <div class="ml-auto flex items-center gap-3">
            <span class="text-sm text-slate-600 dark:text-slate-300">
              {{this.session.account.display_name}}
            </span>
            <button
              type="button"
              class="rounded-md border border-slate-300 px-3 py-1.5 text-sm hover:bg-slate-100 dark:border-slate-600 dark:hover:bg-slate-700"
              {{on "click" this.signOut}}
            >
              Sign out
            </button>
          </div>
        {{else}}
          <LinkTo
            @route="login"
            class="ml-auto text-sm text-slate-700 hover:underline dark:text-slate-200"
          >
            Sign in
          </LinkTo>
        {{/if}}
      </nav>
    </header>
  </template>
}
