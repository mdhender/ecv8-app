import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import { formatDateTime } from 'ec/utils/format';

/**
 * ActivationLink displays a freshly minted magic link.
 *
 * The application does not send email, and the server stores only a hash of the
 * token, so this is the one and only time the link can be read. Losing it means
 * reissuing, which is why the copy below says so plainly.
 */
export default class ActivationLink extends Component {
  @tracked copied = false;

  copy = async () => {
    try {
      await navigator.clipboard.writeText(this.args.link.url);
      this.copied = true;
    } catch {
      // Clipboard access can be denied or unavailable. The URL is selectable in
      // the field below, so there is still a way to get it.
      this.copied = false;
    }
  };

  <template>
    <Alert @kind="success" @title="Activation link created">
      <p class="mt-1">
        Send this link to the account holder yourself. It is shown once, can be
        used only once, and expires
        {{formatDateTime @link.expires_at}}. If it is lost, reissue it.
      </p>

      <div class="mt-3 flex flex-wrap gap-2">
        <label class="sr-only" for="activation-url">Activation link</label>
        <input
          id="activation-url"
          type="text"
          readonly
          value={{@link.url}}
          class="min-w-0 flex-1 rounded-md border border-green-300 bg-white px-3 py-2 font-mono text-xs dark:border-green-700 dark:bg-slate-800"
        />
        <button
          type="button"
          class="rounded-md bg-green-700 px-3 py-2 text-sm font-medium text-white hover:bg-green-800"
          {{on "click" this.copy}}
        >
          {{if this.copied "Copied" "Copy"}}
        </button>
      </div>
    </Alert>
  </template>
}
