# lex-free-energy

Free energy minimization modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements Karl Friston's Free Energy Principle — the theory that cognitive systems minimize prediction error either by updating internal models to match observations (perception/learning) or by taking actions to make observations match predictions (active inference). Tracks prediction errors across domains, updates generative models, and recommends actions that minimize expected future surprise.

## Usage

```ruby
client = Legion::Extensions::FreeEnergy::Client.new

# Compute prediction error after observing an outcome
client.compute_prediction_error(
  domain: :networking,
  predicted: 0.8,     # expected success probability
  observed: 0.3,      # actual outcome
  precision: 1.0
)
# => { error: 0.5, precision_weighted_error: 0.5, surprise: 0.5, surprise_label: :high_surprise }

# Update the generative model from the error
client.update_model(domain: :networking, prediction_error: 0.5)
# => { model_updated: true, complexity_cost: 0.05, new_model_evidence: 0.72 }

# Active inference: recommend the action that minimizes expected free energy
client.active_inference(domain: :networking, goal_state: :stable_connection)
# => { recommended_action: :retry_with_backoff, expected_free_energy: 0.2,
#      epistemic_value: 0.15, pragmatic_value: 0.3 }

# Overall free energy status
client.free_energy_status
# => { total_free_energy: 0.35, minimization_label: :stable, above_threshold: false }

# Model fit for a domain
client.model_evidence(domain: :networking)
# => { evidence: 0.8, model_accuracy: 0.75, surprise_history: [...] }

# Update precision after observing prediction accuracy
client.precision_update(domain: :networking, outcome_accuracy: 0.9)

# Periodic maintenance
client.update_free_energy
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
