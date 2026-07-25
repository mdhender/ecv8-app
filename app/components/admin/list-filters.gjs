import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

/** True when `current` matches `value`, for marking a <select> option. */
function isSelected(current, value) {
  return current === value;
}

/**
 * ListFilters is the search and status filter above an admin list.
 *
 * Submitting navigates rather than filtering in place, so the filters end up in
 * the URL. That keeps a filtered view shareable and reloadable, and it means the
 * server does the filtering across all pages instead of the browser filtering
 * only the page it happens to be holding.
 */
export default class ListFilters extends Component {
  @service router;

  // Each filter reads through to the query parameter in the URL until the user
  // types, so navigating with the back button updates the controls.
  @tracked qEdit;
  @tracked activeEdit;
  @tracked roleEdit;

  get q() {
    return this.qEdit ?? this.args.q ?? '';
  }

  get active() {
    return this.activeEdit ?? this.args.active ?? '';
  }

  get role() {
    return this.roleEdit ?? this.args.role ?? '';
  }

  updateQuery = (event) => {
    this.qEdit = event.target.value;
  };

  updateActive = (event) => {
    this.activeEdit = event.target.value;
  };

  updateRole = (event) => {
    this.roleEdit = event.target.value;
  };

  submit = (event) => {
    event.preventDefault();
    const queryParams = { page: 1, q: this.q, active: this.active };
    if (this.args.showRole) {
      queryParams.role = this.role;
    }
    this.router.transitionTo(this.args.route, { queryParams });
  };

  reset = () => {
    this.qEdit = '';
    this.activeEdit = '';
    this.roleEdit = '';
    this.router.transitionTo(this.args.route, {
      queryParams: { page: 1, q: '', active: '', role: '' },
    });
  };

  <template>
    <form
      class="flex flex-wrap items-end gap-3 rounded-md border border-slate-200 p-4 dark:border-slate-700"
      role="search"
      {{on "submit" this.submit}}
    >
      <div class="min-w-56 flex-1">
        <label
          for="filter-q"
          class="block text-sm font-medium text-slate-700 dark:text-slate-200"
        >
          Search
        </label>
        <input
          id="filter-q"
          type="search"
          value={{this.q}}
          placeholder={{@placeholder}}
          class="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "input" this.updateQuery}}
        />
      </div>

      <div>
        <label
          for="filter-active"
          class="block text-sm font-medium text-slate-700 dark:text-slate-200"
        >
          Status
        </label>
        <select
          id="filter-active"
          class="mt-1 rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "change" this.updateActive}}
        >
          <option value="" selected={{isSelected this.active ""}}>Any</option>
          <option value="true" selected={{isSelected this.active "true"}}>
            Active
          </option>
          <option value="false" selected={{isSelected this.active "false"}}>
            Deactivated
          </option>
        </select>
      </div>

      {{#if @showRole}}
        <div>
          <label
            for="filter-role"
            class="block text-sm font-medium text-slate-700 dark:text-slate-200"
          >
            Role
          </label>
          <select
            id="filter-role"
            class="mt-1 rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateRole}}
          >
            <option value="" selected={{isSelected this.role ""}}>Any</option>
            <option value="user" selected={{isSelected this.role "user"}}>
              User
            </option>
            <option value="admin" selected={{isSelected this.role "admin"}}>
              Administrator
            </option>
          </select>
        </div>
      {{/if}}

      <button
        type="submit"
        class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700"
      >
        Apply
      </button>
      <button
        type="button"
        class="rounded-md border border-slate-300 px-4 py-2 hover:bg-slate-100 dark:border-slate-600 dark:hover:bg-slate-700"
        {{on "click" this.reset}}
      >
        Reset
      </button>
    </form>
  </template>
}
