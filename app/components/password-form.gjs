import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * PasswordForm changes the signed-in account's password.
 *
 * The current password is required, and the server revokes every other session
 * on success, so the note below is a statement of what actually happens rather
 * than a suggestion.
 */
export default class PasswordForm extends Component {
  @service api;
  @service session;

  @tracked currentPassword = '';
  @tracked newPassword = '';
  @tracked confirmation = '';
  @tracked status = null;
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  get isImpersonating() {
    return this.session.isImpersonating;
  }

  updateCurrent = (event) => {
    this.currentPassword = event.target.value;
  };

  updateNew = (event) => {
    this.newPassword = event.target.value;
  };

  updateConfirmation = (event) => {
    this.confirmation = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.status = null;
    this.fieldErrors = {};

    if (this.newPassword !== this.confirmation) {
      this.fieldErrors = { confirmation: 'The two passwords do not match.' };
      return;
    }

    this.isSubmitting = true;
    try {
      await this.api.put('/me/password', {
        current_password: this.currentPassword,
        new_password: this.newPassword,
      });
      this.status =
        'Password changed. Any other sessions have been signed out.';
      this.currentPassword = '';
      this.newPassword = '';
      this.confirmation = '';
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
    {{#if this.isImpersonating}}
      <Alert @kind="info">
        <p>Passwords cannot be changed while impersonating another account.</p>
      </Alert>
    {{else}}
      <form class="space-y-4" {{on "submit" this.submit}}>
        {{#if this.status}}
          <Alert @kind="success"><p>{{this.status}}</p></Alert>
        {{/if}}
        {{#if this.error}}
          <Alert @kind="error" @title="Could not change password">
            <p>{{this.error}}</p>
          </Alert>
        {{/if}}

        <Field
          @name="current-password"
          @label="Current password"
          @required={{true}}
          @error={{this.fieldErrors.current_password}}
          as |f|
        >
          <input
            id={{f.id}}
            type="password"
            autocomplete="current-password"
            required
            aria-describedby={{f.describedBy}}
            value={{this.currentPassword}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateCurrent}}
          />
        </Field>

        <Field
          @name="new-password"
          @label="New password"
          @required={{true}}
          @hint="Between 3 and 128 bytes."
          @error={{this.fieldErrors.new_password}}
          as |f|
        >
          <input
            id={{f.id}}
            type="password"
            autocomplete="new-password"
            required
            aria-describedby={{f.describedBy}}
            value={{this.newPassword}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateNew}}
          />
        </Field>

        <Field
          @name="new-password-confirmation"
          @label="Confirm new password"
          @required={{true}}
          @error={{this.fieldErrors.confirmation}}
          as |f|
        >
          <input
            id={{f.id}}
            type="password"
            autocomplete="new-password"
            required
            aria-describedby={{f.describedBy}}
            value={{this.confirmation}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateConfirmation}}
          />
        </Field>

        <button
          type="submit"
          disabled={{this.isSubmitting}}
          class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          {{if this.isSubmitting "Changing…" "Change password"}}
        </button>
      </form>
    {{/if}}
  </template>
}
