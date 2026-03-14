# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Prospection
      module Helpers
        class Scenario
          include Constants

          attr_reader :id, :domain, :description, :time_horizon, :predicted_valence,
                      :predicted_arousal, :confidence, :vividness, :created_at,
                      :actual_valence, :actual_arousal, :resolved_at

          def initialize(domain:, description:, time_horizon:, predicted_valence:,
                         predicted_arousal:, confidence: nil, **)
            @id                = SecureRandom.uuid
            @domain            = domain
            @description       = description
            @time_horizon      = [time_horizon.to_f, MAX_TIME_HORIZON].min
            @predicted_valence = predicted_valence.clamp(-1.0, 1.0)
            @predicted_arousal = predicted_arousal.clamp(0.0, 1.0)
            @confidence        = (confidence || DEFAULT_CONFIDENCE).clamp(0.0, 1.0)
            @vividness         = DEFAULT_VIVIDNESS
            @created_at        = Time.now.utc
            @actual_valence    = nil
            @actual_arousal    = nil
            @resolved_at       = nil
          end

          def temporal_discount
            1.0 - (TEMPORAL_DISCOUNT_RATE * @time_horizon).clamp(0.0, 0.9)
          end

          def corrected_valence
            @predicted_valence * IMPACT_BIAS_CORRECTION * temporal_discount
          end

          def corrected_arousal
            @predicted_arousal * IMPACT_BIAS_CORRECTION * temporal_discount
          end

          def label
            VALENCE_LABELS.each do |range, lbl|
              return lbl if range.cover?(corrected_valence)
            end
            :ambivalent
          end

          def confidence_label
            CONFIDENCE_LABELS.each do |range, lbl|
              return lbl if range.cover?(@confidence)
            end
            :speculative
          end

          def decay
            @confidence = (@confidence - SCENARIO_DECAY).clamp(0.0, 1.0)
            @vividness  = (@vividness - SCENARIO_DECAY).clamp(0.0, 1.0)
          end

          def reinforce_vividness(amount)
            @vividness = (@vividness + (VIVIDNESS_ALPHA * amount)).clamp(0.0, 1.0)
          end

          def apply_focalism_discount
            @predicted_valence *= (1.0 - FOCALISM_DISCOUNT)
            @predicted_arousal *= (1.0 - FOCALISM_DISCOUNT)
          end

          def resolve(actual_valence:, actual_arousal:)
            @actual_valence = actual_valence.clamp(-1.0, 1.0)
            @actual_arousal = actual_arousal.clamp(0.0, 1.0)
            @resolved_at    = Time.now.utc
          end

          def resolved?
            !@resolved_at.nil?
          end

          def forecast_error
            return nil unless resolved?

            (corrected_valence - @actual_valence).abs
          end

          def expired?
            @confidence < 0.01 && @vividness < 0.01
          end

          def to_h
            {
              id:                @id,
              domain:            @domain,
              description:       @description,
              time_horizon:      @time_horizon,
              predicted_valence: @predicted_valence,
              predicted_arousal: @predicted_arousal,
              corrected_valence: corrected_valence.round(4),
              corrected_arousal: corrected_arousal.round(4),
              confidence:        @confidence.round(4),
              confidence_label:  confidence_label,
              vividness:         @vividness.round(4),
              label:             label,
              resolved:          resolved?,
              forecast_error:    forecast_error&.round(4),
              created_at:        @created_at,
              resolved_at:       @resolved_at
            }
          end
        end
      end
    end
  end
end
