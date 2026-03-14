# frozen_string_literal: true

module Legion
  module Extensions
    module FreeEnergy
      module Helpers
        class Belief
          include Constants

          attr_reader :id, :domain, :content, :precision, :prediction,
                      :last_observation, :prediction_error, :created_at, :updated_at

          def initialize(id:, content:, domain: :general, prediction: {}, precision: DEFAULT_PRECISION)
            @id               = id
            @content          = content
            @domain           = domain
            @prediction       = prediction
            @precision        = precision.clamp(PRECISION_FLOOR, PRECISION_CEILING)
            @last_observation = nil
            @prediction_error = 0.0
            @created_at       = Time.now.utc
            @updated_at       = @created_at
          end

          def observe(observation:)
            @last_observation = observation
            @prediction_error = compute_error(observation)
            update_precision
            @updated_at = Time.now.utc
            self
          end

          def free_energy
            @prediction_error * @precision
          end

          def surprising?
            free_energy > FREE_ENERGY_THRESHOLD
          end

          def surprise_label
            fe = free_energy
            SURPRISE_LABELS.find { |range, _| range.cover?(fe) }&.last || :trivial
          end

          def revise_prediction(observation:)
            merged = @prediction.dup
            observation.each do |key, value|
              current = merged[key]
              merged[key] = if current.is_a?(Numeric) && value.is_a?(Numeric)
                              current + (LEARNING_RATE * (value - current))
                            else
                              value
                            end
            end
            @prediction = merged
            @updated_at = Time.now.utc
            self
          end

          def stale?(now: Time.now.utc)
            (now - @updated_at) > STALE_THRESHOLD
          end

          def decay_precision
            diff = @precision - DEFAULT_PRECISION
            @precision -= diff * PRECISION_DECAY
            @precision = @precision.clamp(PRECISION_FLOOR, PRECISION_CEILING)
          end

          def to_h
            {
              id:               @id,
              domain:           @domain,
              content:          @content,
              prediction:       @prediction,
              last_observation: @last_observation,
              prediction_error: @prediction_error.round(4),
              precision:        @precision.round(4),
              free_energy:      free_energy.round(4),
              surprise_label:   surprise_label,
              surprising:       surprising?,
              created_at:       @created_at,
              updated_at:       @updated_at
            }
          end

          private

          def compute_error(observation)
            return empty_prediction_error(observation) if @prediction.empty?

            shared_keys = @prediction.keys & observation.keys
            return 1.0 if shared_keys.empty?

            errors = shared_keys.map { |k| key_error(@prediction[k], observation[k]) }
            missing_penalty = (@prediction.keys - shared_keys).size * 0.5
            ((errors.sum + missing_penalty) / @prediction.size.to_f).clamp(0.0, 1.0)
          end

          def empty_prediction_error(observation)
            observation.empty? ? 0.0 : 1.0
          end

          def key_error(predicted, observed)
            return (predicted - observed).abs.clamp(0.0, 1.0) if predicted.is_a?(Numeric) && observed.is_a?(Numeric)

            predicted == observed ? 0.0 : 1.0
          end

          def update_precision
            if @prediction_error < 0.2
              @precision += PRECISION_UPDATE_RATE * (1.0 - @prediction_error)
            else
              @precision -= PRECISION_UPDATE_RATE * @prediction_error
            end
            @precision = @precision.clamp(PRECISION_FLOOR, PRECISION_CEILING)
          end
        end
      end
    end
  end
end
