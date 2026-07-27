import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * Marks the option matching the current choice. A `<select>` shows whichever
 * option carries this, and the catalogue is the server's, so the selection has
 * to be derived from the value rather than from the order they arrived in.
 */
function selectedIf(key, current) {
  return key === current ? 'selected' : undefined;
}

/**
 * GameClusterForm is how a game master generates their game's map.
 *
 * The three settings and the bounds they have to stay inside all come from the
 * API, in the same response that said a cluster could be generated at all. None
 * of it is duplicated here: a default written into the client would disagree
 * with the server the first time the engine changed its mind, and a range
 * written here would refuse a value the server accepts — silently, and only for
 * people using this page.
 *
 * The numbers are JSON numbers, unlike the seed on the setup form. That is not
 * an inconsistency: a seed word is a full-range uint64 and cannot survive a
 * JavaScript double, while a radius tops out at 1024 and a stellium count at
 * 10000. Sending those as strings would be ceremony without a reason.
 *
 * Generating is once and for all — every turn is resolved on the map — so the
 * button says so and the server refuses a second attempt whatever this page
 * does.
 */
export default class GameClusterForm extends Component {
  @service api;
  @service router;

  // All three start undefined and read through to what the API offered, so an
  // untouched form submits exactly the server's own defaults.
  @tracked generatorEdit;
  @tracked stelliumCountEdit;
  @tracked radiusEdit;

  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  get options() {
    return this.args.options;
  }

  get generator() {
    return this.generatorEdit ?? this.options.generator;
  }

  get stelliumCount() {
    return this.stelliumCountEdit ?? String(this.options.stellium_count);
  }

  get radius() {
    return this.radiusEdit ?? String(this.options.radius);
  }

  /** The description of whichever generator is selected, shown beneath it. */
  get selectedGenerator() {
    return this.options.generators.find(
      (generator) => generator.key === this.generator,
    );
  }

  get stelliumCountHint() {
    return `A whole number from ${this.options.min_stellium_count} to ${this.options.max_stellium_count}.`;
  }

  get radiusHint() {
    return `A whole number from ${this.options.min_radius} to ${this.options.max_radius}. Coordinates run from −radius to +radius on each axis.`;
  }

  updateGenerator = (event) => {
    this.generatorEdit = event.target.value;
  };

  updateStelliumCount = (event) => {
    this.stelliumCountEdit = event.target.value;
  };

  updateRadius = (event) => {
    this.radiusEdit = event.target.value;
  };

  /**
   * Both numbers have to be present before anything is sent.
   *
   * The inputs are `required` with `min` and `max`, so the browser stops an
   * empty or out-of-range value and says which field and why in the reader's own
   * language — better than a disabled button, which reports that something is
   * wrong without saying what. This guard is the same rule for anything that
   * gets past that; what a setting may actually be is the server's decision, and
   * its answer is rendered against the field it names.
   */
  get isComplete() {
    return this.stelliumCount.trim() !== '' && this.radius.trim() !== '';
  }

  submit = async (event) => {
    event.preventDefault();
    if (!this.isComplete) {
      return;
    }
    this.error = null;
    this.fieldErrors = {};
    this.isSubmitting = true;
    try {
      await this.api.post(`/games/${this.args.gameId}/cluster`, {
        generator: this.generator,
        stellium_count: Number(this.stelliumCount),
        radius: Number(this.radius),
      });
      // The route reloads the page, which now has a cluster, and this form is
      // replaced by the map. Nothing is kept here that would survive that.
      this.router.refresh('games.cluster');
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
    <form
      class="space-y-4 rounded-md border border-slate-200 p-4 dark:border-slate-700"
      {{on "submit" this.submit}}
    >
      <div>
        <h2 class="text-lg font-semibold">Generate this game's cluster</h2>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
          The cluster is the whole of explorable space: a sphere of stelliums
          drawn from this game's seed. A game is generated once, because every
          turn is resolved on the map it produces.
        </p>
      </div>

      {{#if this.error}}
        <Alert @kind="error" @title="Could not generate the cluster">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <div>
        <Field
          @name="cluster-generator"
          @label="Generator"
          @required={{true}}
          @error={{this.fieldErrors.generator}}
          as |f|
        >
          <select
            id={{f.id}}
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            class="w-full max-w-sm rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateGenerator}}
          >
            {{#each this.options.generators as |generator|}}
              <option
                value={{generator.key}}
                selected={{selectedIf generator.key this.generator}}
              >
                {{generator.name}}
              </option>
            {{/each}}
          </select>
        </Field>
        {{#if this.selectedGenerator}}
          <p
            class="mt-1 max-w-prose text-xs text-slate-500 dark:text-slate-400"
          >
            {{this.selectedGenerator.description}}
          </p>
        {{/if}}
      </div>

      <div class="flex flex-wrap items-start gap-4">
        <div class="min-w-56 flex-1">
          <Field
            @name="cluster-stellium-count"
            @label="Stelliums"
            @required={{true}}
            @hint={{this.stelliumCountHint}}
            @error={{this.fieldErrors.stellium_count}}
            as |f|
          >
            <input
              id={{f.id}}
              type="number"
              required
              min={{this.options.min_stellium_count}}
              max={{this.options.max_stellium_count}}
              step="1"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.stelliumCount}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 font-mono dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateStelliumCount}}
            />
          </Field>
        </div>

        <div class="min-w-56 flex-1">
          <Field
            @name="cluster-radius"
            @label="Radius"
            @required={{true}}
            @hint={{this.radiusHint}}
            @error={{this.fieldErrors.radius}}
            as |f|
          >
            <input
              id={{f.id}}
              type="number"
              required
              min={{this.options.min_radius}}
              max={{this.options.max_radius}}
              step="1"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.radius}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 font-mono dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateRadius}}
            />
          </Field>
        </div>
      </div>

      <button
        type="submit"
        disabled={{this.isSubmitting}}
        class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
      >
        {{if this.isSubmitting "Generating…" "Generate the cluster"}}
      </button>

      <p class="text-xs text-slate-500 dark:text-slate-400">
        This cannot be undone or repeated. The same seed and the same settings
        always produce the same map, so what you choose here is recorded
        alongside it.
      </p>
    </form>
  </template>
}
