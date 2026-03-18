# lex-free-energy

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Free energy minimization modeling for the LegionIO cognitive architecture. Implements Karl Friston's Free Energy Principle — the theory that biological systems minimize prediction error (free energy) by either updating their internal models to match sensory input (perception) or taking actions to make sensory input match their predictions (action). Tracks prediction error, model evidence, and surprise across domains. Drives adaptive model updates and active inference (action selection to reduce surprise).

## Gem Info

- **Gem name**: `lex-free-energy`
- **Version**: `0.1.1`
- **Namespace**: `Legion::Extensions::FreeEnergy`
- **Location**: `extensions-agentic/lex-free-energy/`

## File Structure

```
lib/legion/extensions/free_energy/
  free_energy.rb                # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # FE_MODES, SURPRISE_LABELS, MINIMIZATION_STRATEGIES, thresholds
    generative_model.rb         # GenerativeModel: prior + posterior beliefs per domain
    free_energy_engine.rb       # Engine: prediction error, model update, active inference
  runners/
    free_energy.rb              # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `LEARNING_RATE` | 0.1 | Model update rate per prediction error |
| `PRECISION_WEIGHT` | 0.8 | How much prediction errors are weighted by precision |
| `SURPRISE_THRESHOLD` | 0.5 | Free energy above which active inference is triggered |
| `MODEL_COMPLEXITY_PENALTY` | 0.05 | KL divergence cost added per model update |
| `EPISTEMIC_VALUE_WEIGHT` | 0.3 | Weight of information gain vs pragmatic value in action selection |
| `MAX_MODELS` | 50 | Generative model registry cap (one per domain) |
| `MAX_PREDICTION_ERRORS` | 500 | Rolling error log cap |
| `FE_MODES` | `[:perception, :action, :learning, :inference]` | Active inference modes |
| `SURPRISE_LABELS` | range hash | `shocking / high_surprise / moderate / low / expected` |
| `MINIMIZATION_LABELS` | range hash | `minimizing / stable / accumulating / critical` |

## Runners

All methods in `Legion::Extensions::FreeEnergy::Runners::FreeEnergy`.

| Method | Key Args | Returns |
|---|---|---|
| `compute_prediction_error` | `domain:, predicted:, observed:, precision: 1.0` | `{ success:, error:, precision_weighted_error:, surprise:, surprise_label: }` |
| `update_model` | `domain:, prediction_error:, learning_rate: nil` | `{ success:, domain:, model_updated:, complexity_cost:, new_model_evidence: }` |
| `active_inference` | `domain:, goal_state:` | `{ success:, recommended_action:, expected_free_energy:, epistemic_value:, pragmatic_value: }` |
| `free_energy_status` | — | `{ success:, total_free_energy:, minimization_label:, above_threshold:, domain_breakdown: }` |
| `model_evidence` | `domain:` | `{ success:, domain:, evidence:, model_accuracy:, surprise_history: }` |
| `expected_free_energy` | `domain:, action:` | `{ success:, efe:, epistemic_value:, pragmatic_value:, action: }` |
| `precision_update` | `domain:, outcome_accuracy:` | `{ success:, domain:, precision_before:, precision_after: }` |
| `update_free_energy` | — | `{ success:, errors_pruned:, models_updated: }` |
| `free_energy_stats` | — | Full stats hash including per-domain evidence and error rates |

## Helpers

### `GenerativeModel`
Per-domain probabilistic model. Attributes: `domain`, `prior` (float, agent's expectation), `posterior` (float, updated belief), `precision` (inverse variance of prediction errors), `evidence` (accumulated model fit), `complexity` (accumulated KL divergence cost), `update_count`. Key methods: `update!(error:, rate:)` (shifts posterior toward prior + error), `model_evidence` (evidence - complexity), `to_h`.

### `FreeEnergyEngine`
Central store: `@models` (hash by domain), `@errors` (array, rolling). Key methods:
- `compute_error(domain:, predicted:, observed:, precision:)`: computes absolute difference, applies precision weighting, logs error, computes surprise as `error * precision`
- `update_model(domain:, error:, rate:)`: retrieves or creates GenerativeModel, calls `model.update!`, adds complexity penalty
- `active_inference(domain:, goal_state:)`: computes expected free energy for candidate actions = epistemic value (information gain) + pragmatic value (goal proximity), returns lowest EFE action
- `total_free_energy`: sum of all recent prediction errors weighted by domain precision
- `minimization_trend`: compares recent error average to historical average

## Integration Points

- `compute_prediction_error` called from lex-tick's `prediction_engine` phase after each prediction
- `free_energy_status[:above_threshold]` triggers lex-tick to bias toward `:full_active` mode (high surprise = more processing needed)
- `active_inference` informs lex-tick's `action_selection` phase — provides free-energy-minimizing action recommendation
- `model_evidence` feeds lex-prediction's confidence calibration (high evidence = confident predictions)
- `free_energy_status[:total_free_energy]` feeds lex-emotion as a background stress/anxiety signal (unresolved prediction error)
- Precision updates from `precision_update` feed lex-error-monitoring's domain confidence

## Development Notes

- Free energy in this model is an approximation: sum of precision-weighted prediction errors, not the full variational free energy from Friston's formalism
- GenerativeModel uses a single float (`prior`, `posterior`) per domain rather than a full probability distribution
- Active inference action selection: EFE is computed for a small set of candidate actions (defined per domain), returns the minimizing action
- Model complexity penalty is additive per update — complex models accumulate cost even when accurate
- Precision is updated separately via `precision_update`, not automatically from prediction errors
- `INFERENCE_MODES` is validated in both `FreeEnergyEngine#minimize` and the `minimize_free_energy` runner — invalid modes return nil / `{ success: false, reason: :invalid_mode }`
