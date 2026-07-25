import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/** True when `current` matches `value`, for marking a <select> option. */
function isSelected(current, value) {
  return current === value;
}

/**
 * InviteForm creates an account and shows the activation link it produces.
 *
 * There is no public registration, so this is the only way an account comes
 * into existence. The new account has no password until the invitee redeems the
 * link and chooses one.
 */
export default class InviteForm extends Component {
  @service api;
  @service router;
  @service activationLinks;

  @tracked email = '';
  @tracked displayName = '';
  @tracked role = 'user';
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  updateEmail = (event) => {
    this.email = event.target.value;
  };

  updateDisplayName = (event) => {
    this.displayName = event.target.value;
  };

  updateRole = (event) => {
    this.role = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.fieldErrors = {};
    this.isSubmitting = true;
    try {
      const result = await this.api.post('/admin/accounts', {
        email: this.email,
        display_name: this.displayName,
        role: this.role,
      });
      // The link goes to a service, not to local state: the refresh below tears
      // this component down, and losing the URL means reissuing.
      this.activationLinks.remember(result.activation_link);
      this.email = '';
      this.displayName = '';
      this.role = 'user';
      // Refresh only this list route. Refreshing everything would also rebuild
      // the parent admin route, taking the link banner down with it.
      this.router.refresh('admin.accounts.index');
    } catch (error) {
      if (error instanceof ApiError) {
        this.error = error.message;
        this.fieldErrors = error.fields;
      } else {
        this.error = 'Could not reach the server. Try again.';
      }
    } finally {
      this.isSubmitting = false;
    }
  };

  <template>
    <div class="space-y-4">
      <form
        class="grid gap-4 rounded-md border border-slate-200 p-4 sm:grid-cols-2 dark:border-slate-700"
        {{on "submit" this.submit}}
      >
        <h3 class="sm:col-span-2 text-lg font-semibold">Invite an account</h3>

        {{#if this.error}}
          <div class="sm:col-span-2">
            <Alert @kind="error" @title="Could not create the account">
              <p>{{this.error}}</p>
            </Alert>
          </div>
        {{/if}}

        <Field
          @name="invite-email"
          @label="Email"
          @required={{true}}
          @error={{this.fieldErrors.email}}
          as |f|
        >
          <input
            id={{f.id}}
            type="email"
            required
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            value={{this.email}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateEmail}}
          />
        </Field>

        <Field
          @name="invite-display-name"
          @label="Display name"
          @hint="Defaults to the part before the @."
          @error={{this.fieldErrors.display_name}}
          as |f|
        >
          <input
            id={{f.id}}
            type="text"
            maxlength="100"
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            value={{this.displayName}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateDisplayName}}
          />
        </Field>

        <Field
          @name="invite-role"
          @label="Role"
          @hint="Administrators can never be assigned to a game."
          @error={{this.fieldErrors.role}}
          as |f|
        >
          <select
            id={{f.id}}
            aria-describedby={{f.describedBy}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateRole}}
          >
            <option value="user" selected={{isSelected this.role "user"}}>
              User
            </option>
            <option value="admin" selected={{isSelected this.role "admin"}}>
              Administrator
            </option>
          </select>
        </Field>

        <div class="flex items-end">
          <button
            type="submit"
            disabled={{this.isSubmitting}}
            class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
          >
            {{if this.isSubmitting "Creating…" "Create and get link"}}
          </button>
        </div>
      </form>
    </div>
  </template>
}
