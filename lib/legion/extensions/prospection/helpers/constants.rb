# frozen_string_literal: true

module Legion
  module Extensions
    module Prospection
      module Helpers
        module Constants
          MAX_SCENARIOS              = 100
          MAX_FORECASTS_PER_SCENARIO = 10
          MAX_HISTORY                = 200
          SCENARIO_DECAY             = 0.01
          DEFAULT_CONFIDENCE         = 0.4
          IMPACT_BIAS_CORRECTION     = 0.6
          FOCALISM_DISCOUNT          = 0.15
          TEMPORAL_DISCOUNT_RATE     = 0.05
          MAX_TIME_HORIZON           = 365
          VIVIDNESS_ALPHA            = 0.1
          DEFAULT_VIVIDNESS          = 0.5

          VALENCE_LABELS = {
            (0.6..)      => :positive,
            (0.2...0.6)  => :neutral,
            (-0.2...0.2) => :ambivalent,
            (..-0.2)     => :negative
          }.freeze

          CONFIDENCE_LABELS = {
            (0.8..)     => :calibrated,
            (0.5...0.8) => :moderate,
            (0.2...0.5) => :rough,
            (..0.2)     => :speculative
          }.freeze
        end
      end
    end
  end
end
