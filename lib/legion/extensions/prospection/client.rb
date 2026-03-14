# frozen_string_literal: true

require 'legion/extensions/prospection/helpers/constants'
require 'legion/extensions/prospection/helpers/scenario'
require 'legion/extensions/prospection/helpers/prospection_engine'
require 'legion/extensions/prospection/runners/prospection'

module Legion
  module Extensions
    module Prospection
      class Client
        include Runners::Prospection

        attr_reader :prospection_engine

        def initialize(prospection_engine: nil, **)
          @prospection_engine = prospection_engine || Helpers::ProspectionEngine.new
        end
      end
    end
  end
end
