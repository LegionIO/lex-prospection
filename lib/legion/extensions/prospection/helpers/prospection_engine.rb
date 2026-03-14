# frozen_string_literal: true

module Legion
  module Extensions
    module Prospection
      module Helpers
        class ProspectionEngine
          include Constants

          attr_reader :scenarios, :domain_accuracy, :history

          def initialize
            @scenarios       = {}
            @domain_accuracy = {}
            @history         = []
          end

          def imagine(domain:, description:, time_horizon:, predicted_valence:,
                      predicted_arousal:, confidence: nil, **)
            prune_if_full
            scenario = Scenario.new(
              domain:            domain,
              description:       description,
              time_horizon:      time_horizon,
              predicted_valence: predicted_valence,
              predicted_arousal: predicted_arousal,
              confidence:        confidence
            )
            apply_focalism(scenario, domain)
            @scenarios[scenario.id] = scenario
            scenario
          end

          def scenarios_for(domain:)
            @scenarios.values.select { |s| s.domain == domain && !s.resolved? }
          end

          def resolve_scenario(id:, actual_valence:, actual_arousal:)
            scenario = @scenarios[id]
            return nil unless scenario
            return nil if scenario.resolved?

            scenario.resolve(actual_valence: actual_valence, actual_arousal: actual_arousal)
            update_domain_accuracy(scenario)
            record_history(scenario)
            scenario
          end

          def accuracy_for(domain)
            1.0 - @domain_accuracy.fetch(domain, 0.0)
          end

          def near_future(days: 7)
            @scenarios.values.select { |s| !s.resolved? && s.time_horizon <= days }
          end

          def most_vivid(count: 5)
            @scenarios.values
                      .reject(&:resolved?)
                      .sort_by { |s| -s.vividness }
                      .first(count)
          end

          def decay_all
            @scenarios.each_value(&:decay)
            @scenarios.reject! { |_, s| s.expired? }
          end

          def remove_scenario(id:)
            @scenarios.delete(id)
          end

          def scenario_count
            @scenarios.size
          end

          def domain_count
            @scenarios.values.map(&:domain).uniq.size
          end

          def to_h
            {
              scenario_count:  scenario_count,
              domain_count:    domain_count,
              history_size:    @history.size,
              domain_accuracy: @domain_accuracy.transform_values { |v| (1.0 - v).round(4) }
            }
          end

          private

          def apply_focalism(scenario, domain)
            active = scenarios_for(domain: domain)
            scenario.apply_focalism_discount if active.size >= 1
          end

          def update_domain_accuracy(scenario)
            error = scenario.forecast_error || 0.0
            existing = @domain_accuracy.fetch(scenario.domain, error)
            @domain_accuracy[scenario.domain] = existing + (VIVIDNESS_ALPHA * (error - existing))
          end

          def record_history(scenario)
            @history << {
              scenario_id:    scenario.id,
              domain:         scenario.domain,
              forecast_error: scenario.forecast_error,
              resolved_at:    scenario.resolved_at
            }
            @history.shift while @history.size > MAX_HISTORY
          end

          def prune_if_full
            return unless @scenarios.size >= MAX_SCENARIOS

            oldest = @scenarios.values
                               .reject(&:resolved?)
                               .min_by(&:created_at)
            @scenarios.delete(oldest.id) if oldest
          end
        end
      end
    end
  end
end
