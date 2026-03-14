# frozen_string_literal: true

require_relative 'free_energy/version'
require_relative 'free_energy/helpers/constants'
require_relative 'free_energy/helpers/belief'
require_relative 'free_energy/helpers/free_energy_engine'
require_relative 'free_energy/runners/free_energy'
require_relative 'free_energy/client'

module Legion
  module Extensions
    module FreeEnergy
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
