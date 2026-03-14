# frozen_string_literal: true

module Legion
  module Extensions
    module FreeEnergy
      module Helpers
        module Constants
          # Maximum generative-model beliefs
          MAX_BELIEFS = 200

          # Maximum planned actions
          MAX_ACTIONS = 100

          # Maximum event history
          MAX_HISTORY = 300

          # Default precision (inverse variance / confidence in prediction)
          DEFAULT_PRECISION = 0.5

          # Precision bounds
          PRECISION_FLOOR   = 0.05
          PRECISION_CEILING = 0.95

          # Free energy above this triggers high-surprise state
          FREE_ENERGY_THRESHOLD = 0.5

          # Learning rate for belief updates (perceptual inference)
          LEARNING_RATE = 0.1

          # Rate at which precision adapts to prediction errors
          PRECISION_UPDATE_RATE = 0.05

          # Precision decay toward default for stale beliefs
          PRECISION_DECAY = 0.01

          # How stale (seconds) before precision decays
          STALE_THRESHOLD = 120

          # Free energy minimization strategies
          INFERENCE_MODES = %i[perceptual active].freeze

          # Surprise magnitude labels
          SURPRISE_LABELS = {
            (0.8..)     => :shocking,
            (0.6...0.8) => :surprising,
            (0.4...0.6) => :notable,
            (0.2...0.4) => :expected,
            (..0.2)     => :trivial
          }.freeze
        end
      end
    end
  end
end
