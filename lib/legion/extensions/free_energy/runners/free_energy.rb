# frozen_string_literal: true

module Legion
  module Extensions
    module FreeEnergy
      module Runners
        module FreeEnergy
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def add_generative_belief(content:, domain: :general, prediction: {}, precision: DEFAULT_PRECISION, **)
            belief = engine.add_belief(content: content, domain: domain, prediction: prediction, precision: precision)
            return { success: false, reason: :limit_reached } unless belief

            { success: true, belief_id: belief.id, precision: belief.precision }
          end

          def observe_outcome(belief_id:, observation:, **)
            belief = engine.observe(belief_id: belief_id, observation: observation)
            return { success: false, reason: :not_found } unless belief

            {
              success:          true,
              belief_id:        belief_id,
              prediction_error: belief.prediction_error.round(4),
              free_energy:      belief.free_energy.round(4),
              surprising:       belief.surprising?,
              surprise_label:   belief.surprise_label
            }
          end

          def minimize_free_energy(belief_id:, mode: :perceptual, **)
            result = engine.minimize(belief_id: belief_id, mode: mode)
            return { success: false, reason: :not_found } unless result

            if mode == :active
              { success: true, mode: :active }.merge(result)
            else
              { success: true, mode: :perceptual, belief_id: result.id, prediction: result.prediction }
            end
          end

          def compute_free_energy(**)
            {
              success:             true,
              total_free_energy:   engine.total_free_energy.round(4),
              surprise_level:      engine.surprise_level,
              high_surprise_count: engine.high_surprise_beliefs.size
            }
          end

          def surprise_assessment(**)
            {
              success:         true,
              surprise_level:  engine.surprise_level,
              most_surprising: engine.most_surprising,
              most_precise:    engine.most_precise
            }
          end

          def high_surprise_beliefs(**)
            beliefs = engine.high_surprise_beliefs
            { success: true, beliefs: beliefs, count: beliefs.size }
          end

          def domain_free_energy(domain:, **)
            {
              success:      true,
              domain:       domain,
              free_energy:  engine.domain_free_energy(domain: domain).round(4),
              belief_count: engine.domain_beliefs(domain: domain).size
            }
          end

          def update_free_energy(**)
            engine.decay_stale
            { success: true }.merge(engine.to_h)
          end

          def free_energy_stats(**)
            { success: true }.merge(engine.to_h)
          end

          private

          def engine
            @engine ||= Helpers::FreeEnergyEngine.new
          end
        end
      end
    end
  end
end
