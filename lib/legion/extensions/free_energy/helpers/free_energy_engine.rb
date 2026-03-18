# frozen_string_literal: true

module Legion
  module Extensions
    module FreeEnergy
      module Helpers
        class FreeEnergyEngine
          include Constants

          attr_reader :beliefs, :history

          def initialize
            @beliefs      = {}
            @belief_count = 0
            @history      = []
          end

          def add_belief(content:, domain: :general, prediction: {}, precision: DEFAULT_PRECISION)
            return nil if @beliefs.size >= MAX_BELIEFS

            @belief_count += 1
            belief = Belief.new(
              id:         :"belief_#{@belief_count}",
              content:    content,
              domain:     domain,
              prediction: prediction,
              precision:  precision
            )
            @beliefs[belief.id] = belief
            record_event(:add_belief, belief_id: belief.id)
            belief
          end

          def observe(belief_id:, observation:)
            belief = @beliefs[belief_id]
            return nil unless belief

            belief.observe(observation: observation)
            record_event(:observe, belief_id: belief_id, error: belief.prediction_error)
            belief
          end

          def minimize_perceptual(belief_id:)
            belief = @beliefs[belief_id]
            return nil unless belief
            return nil unless belief.last_observation

            belief.revise_prediction(observation: belief.last_observation)
            record_event(:minimize_perceptual, belief_id: belief_id)
            belief
          end

          def minimize_active(belief_id:)
            belief = @beliefs[belief_id]
            return nil unless belief

            action = {
              type:      :active_inference,
              belief_id: belief_id,
              target:    belief.prediction,
              urgency:   belief.free_energy
            }
            record_event(:minimize_active, belief_id: belief_id, action: action)
            action
          end

          def minimize(belief_id:, mode: :perceptual)
            return nil unless INFERENCE_MODES.include?(mode)

            case mode
            when :perceptual then minimize_perceptual(belief_id: belief_id)
            when :active     then minimize_active(belief_id: belief_id)
            end
          end

          def total_free_energy
            return 0.0 if @beliefs.empty?

            @beliefs.values.sum(&:free_energy) / @beliefs.size.to_f
          end

          def surprise_level
            fe = total_free_energy
            SURPRISE_LABELS.find { |range, _| range.cover?(fe) }&.last || :trivial
          end

          def high_surprise_beliefs
            @beliefs.values.select(&:surprising?).map(&:to_h)
          end

          def domain_beliefs(domain:)
            @beliefs.values.select { |b| b.domain == domain }
          end

          def domain_free_energy(domain:)
            relevant = domain_beliefs(domain: domain)
            return 0.0 if relevant.empty?

            relevant.sum(&:free_energy) / relevant.size.to_f
          end

          def most_surprising(limit: 5)
            @beliefs.values
                    .sort_by { |b| -b.free_energy }
                    .first(limit)
                    .map(&:to_h)
          end

          def most_precise(limit: 5)
            @beliefs.values
                    .sort_by { |b| -b.precision }
                    .first(limit)
                    .map(&:to_h)
          end

          def decay_stale
            now = Time.now.utc
            @beliefs.each_value do |belief|
              belief.decay_precision if belief.stale?(now: now)
            end
          end

          def remove_belief(belief_id:)
            @beliefs.delete(belief_id)
          end

          def to_h
            {
              belief_count:        @beliefs.size,
              total_free_energy:   total_free_energy.round(4),
              surprise_level:      surprise_level,
              high_surprise_count: @beliefs.values.count(&:surprising?),
              mean_precision:      mean_precision.round(4),
              history_size:        @history.size
            }
          end

          private

          def mean_precision
            return DEFAULT_PRECISION if @beliefs.empty?

            @beliefs.values.sum(&:precision) / @beliefs.size.to_f
          end

          def record_event(type, **details)
            @history << { type: type, at: Time.now.utc }.merge(details)
            @history.shift while @history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
