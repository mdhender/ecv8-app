import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * ActivateForm redeems a magic link and sets the account's first password.
 *
 * The token comes from the URL and is single-use, so a failure is terminal:
 * there is no retry that could succeed, and the message says to ask an
 * administrator for a new link rather than inviting the user to try again.
 */
export default class ActivateForm extends Component {
  @service session;
  @service api;
  @service router;

  @tracked password = '';
  @tracked confirmation = '';
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isExpired = false;
  @tracked isSubmitting = false;

  get hasToken() {
    return Boolean(this.args.token);
  }

  updatePassword = (event) => {
    this.password = event.target.value;
  };

  updateConfirmation = (event) => {
    this.confirmation = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.fieldErrors = {};

    if (this.password !== this.confirmation) {
      this.fieldErrors = { confirmation: 'The two passwords do not match.' };
      return;
    }

    this.isSubmitting = true;
    try {
      await this.api.post('/activation', {
        token: this.args.token,
        password: this.password,
      });
      // The server signed the account in as part of redeeming the link, so the
      // cookie is already set. Restoring picks it up without asking for
      // credentials the user has just finished choosing.
      await this.session.refresh();
      this.router.transitionTo('dashboard');
    } catch (error) {
      if (error instanceof ApiError) {
        this.isExpired = error.isGone;
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
    {{#unless this.hasToken}}
      <Alert @kind="error" @title="This link is incomplete">
        <p>
          The activation link is missing its token. Use the full link an
          administrator sent you, or ask for a new one.
        </p>
      </Alert>
    {{/unless}}

    {{#if this.hasToken}}
      <form class="space-y-4" {{on "submit" this.submit}}>
        {{#if this.error}}
          <Alert
            @kind="error"
            @title={{if
              this.isExpired
              "This link no longer works"
              "Activation failed"
            }}
          >
            <p>{{this.error}}</p>
          </Alert>
        {{/if}}

        <Field
          @name="password"
          @label="Choose a password"
          @required={{true}}
          @hint="Between 3 and 128 bytes."
          @error={{this.fieldErrors.password}}
          as |f|
        >
          <input
            id={{f.id}}
            type="password"
            name="new-password"
            autocomplete="new-password"
            required
            aria-describedby={{f.describedBy}}
            value={{this.password}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updatePassword}}
          />
        </Field>

        <Field
          @name="confirmation"
          @label="Confirm password"
          @required={{true}}
          @error={{this.fieldErrors.confirmation}}
          as |f|
        >
          <input
            id={{f.id}}
            type="password"
            name="confirm-password"
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
          class="w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          {{if this.isSubmitting "Activating…" "Activate account"}}
        </button>
      </form>
    {{/if}}
  </template>
}
