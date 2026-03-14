# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/prospection/version'
require 'legion/extensions/prospection/helpers/constants'
require 'legion/extensions/prospection/helpers/scenario'
require 'legion/extensions/prospection/helpers/prospection_engine'
require 'legion/extensions/prospection/runners/prospection'
require 'legion/extensions/prospection/client'

module Legion
  module Extensions
    module Prospection
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
