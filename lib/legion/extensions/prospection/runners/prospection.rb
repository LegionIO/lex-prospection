# frozen_string_literal: true

module Legion
  module Extensions
    module Prospection
      module Runners
        module Prospection
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def imagine_future(domain:, description:, time_horizon:, predicted_valence:,
                             predicted_arousal:, confidence: nil, **)
            scenario = prospection_engine.imagine(
              domain:            domain,
              description:       description,
              time_horizon:      time_horizon,
              predicted_valence: predicted_valence,
              predicted_arousal: predicted_arousal,
              confidence:        confidence
            )
            Legion::Logging.debug \
              "[prospection] imagine: domain=#{domain} horizon=#{time_horizon}d " \
              "valence=#{predicted_valence.round(3)} label=#{scenario.label}"
            {
              success:           true,
              scenario_id:       scenario.id,
              domain:            scenario.domain,
              label:             scenario.label,
              corrected_valence: scenario.corrected_valence.round(4),
              corrected_arousal: scenario.corrected_arousal.round(4),
              confidence:        scenario.confidence.round(4),
              confidence_label:  scenario.confidence_label
            }
          end

          def resolve_future(scenario_id:, actual_valence:, actual_arousal:, **)
            scenario = prospection_engine.resolve_scenario(
              id:             scenario_id,
              actual_valence: actual_valence,
              actual_arousal: actual_arousal
            )
            unless scenario
              Legion::Logging.debug "[prospection] resolve: id=#{scenario_id} not_found_or_already_resolved"
              return { success: false, reason: :not_found }
            end
            Legion::Logging.debug \
              "[prospection] resolve: id=#{scenario_id} domain=#{scenario.domain} " \
              "error=#{scenario.forecast_error&.round(3)}"
            {
              success:        true,
              scenario_id:    scenario.id,
              domain:         scenario.domain,
              forecast_error: scenario.forecast_error&.round(4),
              actual_valence: actual_valence,
              actual_arousal: actual_arousal
            }
          end

          def forecast_accuracy(domain: :general, **)
            accuracy = prospection_engine.accuracy_for(domain)
            Legion::Logging.debug "[prospection] accuracy: domain=#{domain} accuracy=#{accuracy.round(3)}"
            { success: true, domain: domain, accuracy: accuracy.round(4) }
          end

          def near_future_scenarios(days: 7, **)
            scenarios = prospection_engine.near_future(days: days)
            Legion::Logging.debug "[prospection] near_future: days=#{days} count=#{scenarios.size}"
            {
              success:   true,
              days:      days,
              scenarios: scenarios.map(&:to_h),
              count:     scenarios.size
            }
          end

          def vivid_scenarios(count: 5, **)
            scenarios = prospection_engine.most_vivid(count: count)
            Legion::Logging.debug "[prospection] vivid: count=#{scenarios.size}"
            {
              success:   true,
              scenarios: scenarios.map(&:to_h),
              count:     scenarios.size
            }
          end

          def scenarios_in_domain(domain:, **)
            scenarios = prospection_engine.scenarios_for(domain: domain)
            Legion::Logging.debug "[prospection] domain_scenarios: domain=#{domain} count=#{scenarios.size}"
            {
              success:   true,
              domain:    domain,
              scenarios: scenarios.map(&:to_h),
              count:     scenarios.size
            }
          end

          def update_prospection(**)
            prospection_engine.decay_all
            stats = prospection_engine.to_h
            Legion::Logging.debug \
              "[prospection] tick: scenarios=#{stats[:scenario_count]} " \
              "domains=#{stats[:domain_count]} history=#{stats[:history_size]}"
            { success: true }.merge(stats)
          end

          def prospection_stats(**)
            stats = prospection_engine.to_h
            Legion::Logging.debug \
              "[prospection] stats: scenarios=#{stats[:scenario_count]} " \
              "domains=#{stats[:domain_count]}"
            { success: true, stats: stats }
          end

          private

          def prospection_engine
            @prospection_engine ||= Helpers::ProspectionEngine.new
          end
        end
      end
    end
  end
end
