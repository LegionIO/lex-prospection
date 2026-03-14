# lex-prospection

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-prospection`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::Prospection`

## Purpose

Mental time travel and future scenario simulation. Imagines future scenarios with predicted emotional valence and arousal, applies cognitive bias corrections (impact bias, focalism discount), and tracks forecast accuracy per domain when scenarios are resolved against actual outcomes. Vividness decays over time; expired scenarios are pruned automatically.

## Gem Info

- **Homepage**: https://github.com/LegionIO/lex-prospection
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/prospection/
  version.rb
  client.rb
  helpers/
    constants.rb           # Bias corrections, decay, labels, limits
    scenario.rb            # Scenario class — future scenario with corrections
    prospection_engine.rb  # ProspectionEngine — imagine, resolve, accuracy tracking
  runners/
    prospection.rb         # Runner module
  actors/
    decay.rb               # Periodic decay actor
spec/
  helpers/scenario_spec.rb
  helpers/prospection_engine_spec.rb
  runners/prospection_spec.rb
  client_spec.rb
```

## Key Constants

From `Helpers::Constants`:
- `MAX_SCENARIOS = 100`, `MAX_FORECASTS_PER_SCENARIO = 10`, `MAX_HISTORY = 200`
- `SCENARIO_DECAY = 0.01`, `DEFAULT_CONFIDENCE = 0.4`, `DEFAULT_VIVIDNESS = 0.5`
- `IMPACT_BIAS_CORRECTION = 0.6` (predicted impact dampened by 40%)
- `FOCALISM_DISCOUNT = 0.15` (applied when other scenarios already exist for domain)
- `TEMPORAL_DISCOUNT_RATE = 0.05` (per time horizon unit)
- `MAX_TIME_HORIZON = 365` (days)
- `VIVIDNESS_ALPHA = 0.1` (EMA for domain accuracy tracking)
- `VALENCE_LABELS`: `:positive` (>= 0.6), `:neutral`, `:ambivalent`, `:negative`
- `CONFIDENCE_LABELS`: `:calibrated` (>= 0.8), `:moderate`, `:rough`, `:speculative`

## Runners

| Method | Key Parameters | Returns |
|---|---|---|
| `imagine_future` | `domain:`, `description:`, `time_horizon:` (days), `predicted_valence:`, `predicted_arousal:`, `confidence:` | scenario_id, label, corrected_valence, corrected_arousal, confidence_label |
| `resolve_future` | `scenario_id:`, `actual_valence:`, `actual_arousal:` | `{ success:, scenario_id:, domain:, forecast_error:, actual_valence:, actual_arousal: }` |
| `forecast_accuracy` | `domain: :general` | `{ success:, domain:, accuracy: }` (1.0 - avg_error) |
| `near_future_scenarios` | `days: 7` | scenarios with `time_horizon` <= days |
| `vivid_scenarios` | `count: 5` | most vivid unresolved scenarios |
| `scenarios_in_domain` | `domain:` | unresolved scenarios for domain |
| `update_prospection` | — | decay + prune expired scenarios |
| `prospection_stats` | — | scenario count, domain count, history size, domain accuracy map |

## Helpers

### `Helpers::Scenario`
Future scenario: `id`, `domain`, `description`, `time_horizon`, `predicted_valence`, `predicted_arousal`, `vividness`, `confidence`, `resolved_at`, `actual_valence`, `actual_arousal`. `corrected_valence` / `corrected_arousal` = predicted * `IMPACT_BIAS_CORRECTION`. `apply_focalism_discount` further reduces corrected values by `FOCALISM_DISCOUNT`. `resolve(actual_valence:, actual_arousal:)` marks resolved and computes `forecast_error` = mean of abs errors on valence and arousal. `label` = `VALENCE_LABELS` match on corrected_valence. `decay` reduces vividness by `SCENARIO_DECAY`. `expired?` = vividness <= 0.

### `Helpers::ProspectionEngine`
Manages `@scenarios`, `@domain_accuracy`, `@history`. `imagine` creates and applies focalism if other domain scenarios exist. `resolve_scenario` marks resolved, updates domain accuracy via EMA (VIVIDNESS_ALPHA). `accuracy_for(domain)` = 1.0 - domain_accuracy entry. `near_future(days:)` filters by time_horizon. `most_vivid(count:)` sorts by vividness descending. `decay_all` decays and removes expired scenarios.

## Integration Points

- `imagine_future` can accept predictions from `lex-prediction` forward models
- Resolved scenarios feed domain accuracy back into `lex-prediction` calibration
- `near_future_scenarios` can trigger `lex-prospective-memory` intention monitoring
- `vivid_scenarios` with negative valence can heighten `lex-emotion` arousal
- `forecast_accuracy` per domain feeds `lex-reflection` prediction calibration health score
- `update_prospection` called via `actors/decay.rb` periodic actor

## Development Notes

- Impact bias correction: `corrected_valence = predicted_valence * IMPACT_BIAS_CORRECTION` (reduces overestimation)
- Focalism discount: applied when >= 1 other scenario already exists for the same domain
- `forecast_error` = mean(abs(predicted_valence - actual_valence), abs(predicted_arousal - actual_arousal))
- Domain accuracy tracked via EMA of forecast error: low accuracy = high average error
- `expired?` = vividness <= 0; `decay_all` removes expired scenarios in the same call
- All state is in-memory; reset on process restart
