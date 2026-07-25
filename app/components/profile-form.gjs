import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * ProfileForm edits the fields an account may change about itself.
 *
 * Email, role, and active state are missing on purpose: those are
 * administrator-only and the API refuses them here, so offering them would only
 * produce a rejection.
 */
export default class ProfileForm extends Component {
  @service api;
  @service session;

  // Each field starts as undefined and reads through to the loaded account
  // until the user edits it, so a reloaded record is not masked by stale local
  // state.
  @tracked displayNameEdit;
  @tracked timezoneEdit;

  get displayName() {
    return this.displayNameEdit ?? this.args.account.display_name;
  }

  get timezone() {
    return this.timezoneEdit ?? this.args.account.timezone;
  }
  @tracked status = null;
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  updateDisplayName = (event) => {
    this.displayNameEdit = event.target.value;
  };

  updateTimezone = (event) => {
    this.timezoneEdit = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.status = null;
    this.fieldErrors = {};
    this.isSubmitting = true;
    try {
      await this.api.patch('/me', {
        display_name: this.displayName,
        timezone: this.timezone,
      });
      this.status = 'Profile saved.';
      // Re-read the session so the navigation bar shows the new display name.
      // The server's copy is the one that matters, so it is fetched rather than
      // patched in from the response.
      await this.session.refresh();
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
    <form class="space-y-4" {{on "submit" this.submit}}>
      {{#if this.status}}
        <Alert @kind="success"><p>{{this.status}}</p></Alert>
      {{/if}}
      {{#if this.error}}
        <Alert @kind="error" @title="Could not save"><p
          >{{this.error}}</p></Alert>
      {{/if}}

      <Field
        @name="display-name"
        @label="Display name"
        @required={{true}}
        @error={{this.fieldErrors.display_name}}
        as |f|
      >
        <input
          id={{f.id}}
          type="text"
          required
          maxlength="100"
          aria-invalid={{f.invalid}}
          aria-describedby={{f.describedBy}}
          value={{this.displayName}}
          class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "input" this.updateDisplayName}}
        />
      </Field>

      <Field
        @name="timezone"
        @label="Time zone"
        @hint="An IANA name such as America/Chicago."
        @error={{this.fieldErrors.timezone}}
        as |f|
      >
        <input
          id={{f.id}}
          type="text"
          aria-invalid={{f.invalid}}
          aria-describedby={{f.describedBy}}
          value={{this.timezone}}
          class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "input" this.updateTimezone}}
        />
      </Field>

      <button
        type="submit"
        disabled={{this.isSubmitting}}
        class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
      >
        {{if this.isSubmitting "Saving…" "Save profile"}}
      </button>
    </form>
  </template>
}
