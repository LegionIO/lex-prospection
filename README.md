# lex-prospection

Mental time travel and future scenario simulation for the LegionIO cognitive architecture. Imagines future events with emotional predictions and tracks forecast accuracy.

## What It Does

Simulates future scenarios with predicted emotional valence and arousal. Applies two cognitive bias corrections: impact bias correction (reduces overestimation of emotional intensity) and focalism discount (reduces confidence when multiple scenarios compete for attention in the same domain). When scenarios are resolved against actual outcomes, forecast accuracy is tracked per domain.

## Usage

```ruby
client = Legion::Extensions::Prospection::Client.new

# Imagine a future scenario
scenario = client.imagine_future(
  domain:            :deployment,
  description:       'Deploy new service to production',
  time_horizon:      7,       # days from now
  predicted_valence: 0.6,     # expecting positive outcome
  predicted_arousal: 0.7,     # anticipation is high
  confidence:        0.7
)
# => { success: true, scenario_id: '...', label: :positive,
#      corrected_valence: 0.36, corrected_arousal: 0.42,
#      confidence: 0.7, confidence_label: :moderate }

# See upcoming scenarios
client.near_future_scenarios(days: 7)
client.vivid_scenarios(count: 5)

# Resolve after outcome observed
client.resolve_future(
  scenario_id:    scenario[:scenario_id],
  actual_valence: 0.7,
  actual_arousal: 0.4
)
# => { success: true, forecast_error: 0.17, actual_valence: 0.7, actual_arousal: 0.4 }

# Check forecast accuracy for domain
client.forecast_accuracy(domain: :deployment)
# => { success: true, domain: :deployment, accuracy: 0.83 }

# Periodic decay (vividness fades)
client.update_prospection
client.prospection_stats
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
