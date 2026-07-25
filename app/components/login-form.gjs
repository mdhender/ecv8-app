import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * LoginForm signs an account in through Ember Simple Auth.
 *
 * On success the session service decides where to go: back to whatever page the
 * user originally asked for, or the dashboard. The server's rejection message
 * is shown verbatim because it is intentionally identical for a wrong password,
 * an unknown address, and a deactivated account.
 */
export default class LoginForm extends Component {
  @service session;

  @tracked email = '';
  @tracked password = '';
  @tracked error = null;
  @tracked isSubmitting = false;

  updateEmail = (event) => {
    this.email = event.target.value;
  };

  updatePassword = (event) => {
    this.password = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.isSubmitting = true;
    try {
      await this.session.authenticate(
        'authenticator:cookie',
        this.email,
        this.password,
      );
    } catch (error) {
      this.error =
        error instanceof ApiError
          ? error.message
          : 'Could not reach the server. Try again.';
    } finally {
      this.isSubmitting = false;
    }
  };

  <template>
    <form class="space-y-4" {{on "submit" this.submit}}>
      {{#if this.error}}
        <Alert @kind="error" @title="Sign in failed">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <Field @name="email" @label="Email" @required={{true}} as |f|>
        <input
          id={{f.id}}
          type="email"
          name="email"
          autocomplete="username"
          required
          value={{this.email}}
          class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "input" this.updateEmail}}
        />
      </Field>

      <Field @name="password" @label="Password" @required={{true}} as |f|>
        <input
          id={{f.id}}
          type="password"
          name="password"
          autocomplete="current-password"
          required
          value={{this.password}}
          class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
          {{on "input" this.updatePassword}}
        />
      </Field>

      <button
        type="submit"
        disabled={{this.isSubmitting}}
        class="w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
      >
        {{if this.isSubmitting "Signing in…" "Sign in"}}
      </button>
    </form>
  </template>
}
