import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import ActivationLink from 'ec/components/admin/activation-link';

/**
 * ActivationLinkBanner shows the most recently issued magic link.
 *
 * It renders from the activation-links service and is placed on the admin route
 * rather than inside the forms that create links, so it outlives the route
 * refreshes those forms trigger. See the service for why that matters.
 */
export default class ActivationLinkBanner extends Component {
  @service activationLinks;

  dismiss = () => {
    this.activationLinks.dismiss();
  };

  <template>
    {{#if this.activationLinks.latest}}
      <div class="space-y-2">
        <ActivationLink @link={{this.activationLinks.latest}} />
        <button
          type="button"
          class="text-sm text-slate-600 underline dark:text-slate-300"
          {{on "click" this.dismiss}}
        >
          Dismiss this link
        </button>
      </div>
    {{/if}}
  </template>
}
