# frozen_string_literal: true

RSpec.describe Legion::Extensions::FreeEnergy::Helpers::FreeEnergyEngine do
  subject(:engine) { described_class.new }

  let(:constants) { Legion::Extensions::FreeEnergy::Helpers::Constants }

  describe '#initialize' do
    it 'starts with empty beliefs' do
      expect(engine.beliefs).to be_empty
    end

    it 'starts with empty history' do
      expect(engine.history).to be_empty
    end
  end

  describe '#add_belief' do
    it 'creates a belief' do
      belief = engine.add_belief(content: 'test model', domain: :test)
      expect(belief).to be_a(Legion::Extensions::FreeEnergy::Helpers::Belief)
    end

    it 'assigns sequential IDs' do
      first  = engine.add_belief(content: 'first')
      second = engine.add_belief(content: 'second')
      expect(first.id).to be_a(Symbol)
      expect(second.id).not_to eq(first.id)
    end

    it 'stores the belief' do
      belief = engine.add_belief(content: 'stored')
      expect(engine.beliefs[belief.id]).to be(belief)
    end

    it 'respects MAX_BELIEFS limit' do
      constants::MAX_BELIEFS.times { |i| engine.add_belief(content: "belief #{i}") }
      expect(engine.add_belief(content: 'overflow')).to be_nil
    end

    it 'records history event' do
      engine.add_belief(content: 'tracked')
      expect(engine.history.last[:type]).to eq(:add_belief)
    end
  end

  describe '#observe' do
    let!(:belief) { engine.add_belief(content: 'weather', prediction: { temp: 0.7 }) }

    it 'updates the belief with observation' do
      result = engine.observe(belief_id: belief.id, observation: { temp: 0.7 })
      expect(result.prediction_error).to eq(0.0)
    end

    it 'returns nil for unknown belief' do
      expect(engine.observe(belief_id: :nonexistent, observation: {})).to be_nil
    end

    it 'records history event' do
      engine.observe(belief_id: belief.id, observation: { temp: 0.5 })
      expect(engine.history.last[:type]).to eq(:observe)
    end
  end

  describe '#minimize_perceptual' do
    let!(:belief) { engine.add_belief(content: 'model', prediction: { v: 0.3 }) }

    it 'revises prediction toward observation' do
      engine.observe(belief_id: belief.id, observation: { v: 0.9 })
      engine.minimize_perceptual(belief_id: belief.id)
      expect(belief.prediction[:v]).to be > 0.3
    end

    it 'returns nil for unknown belief' do
      expect(engine.minimize_perceptual(belief_id: :nonexistent)).to be_nil
    end

    it 'returns nil when no observation exists' do
      expect(engine.minimize_perceptual(belief_id: belief.id)).to be_nil
    end
  end

  describe '#minimize_active' do
    let!(:belief) { engine.add_belief(content: 'model', prediction: { v: 0.8 }) }

    it 'returns an action plan' do
      action = engine.minimize_active(belief_id: belief.id)
      expect(action[:type]).to eq(:active_inference)
      expect(action[:target]).to eq(belief.prediction)
    end

    it 'returns nil for unknown belief' do
      expect(engine.minimize_active(belief_id: :nonexistent)).to be_nil
    end
  end

  describe '#minimize' do
    let!(:belief) { engine.add_belief(content: 'model', prediction: { v: 0.5 }) }

    it 'delegates to perceptual mode' do
      engine.observe(belief_id: belief.id, observation: { v: 0.9 })
      result = engine.minimize(belief_id: belief.id, mode: :perceptual)
      expect(result).to be_a(Legion::Extensions::FreeEnergy::Helpers::Belief)
    end

    it 'delegates to active mode' do
      result = engine.minimize(belief_id: belief.id, mode: :active)
      expect(result[:type]).to eq(:active_inference)
    end

    it 'returns nil for invalid mode' do
      expect(engine.minimize(belief_id: belief.id, mode: :bogus)).to be_nil
    end

    it 'accepts all valid INFERENCE_MODES' do
      constants::INFERENCE_MODES.each do |mode|
        expect { engine.minimize(belief_id: belief.id, mode: mode) }.not_to raise_error
      end
    end
  end

  describe '#total_free_energy' do
    it 'returns zero with no beliefs' do
      expect(engine.total_free_energy).to eq(0.0)
    end

    it 'returns average free energy across beliefs' do
      b = engine.add_belief(content: 'test', prediction: { v: 0.9 })
      engine.observe(belief_id: b.id, observation: { v: 0.0 })
      expect(engine.total_free_energy).to be > 0.0
    end
  end

  describe '#surprise_level' do
    it 'returns :trivial with no beliefs' do
      expect(engine.surprise_level).to eq(:trivial)
    end

    it 'reflects high surprise when predictions fail' do
      b = engine.add_belief(content: 'test', prediction: { v: 1.0 }, precision: 0.9)
      engine.observe(belief_id: b.id, observation: { v: 0.0 })
      expect(engine.surprise_level).not_to eq(:trivial)
    end
  end

  describe '#high_surprise_beliefs' do
    it 'returns empty when no surprises' do
      engine.add_belief(content: 'calm')
      expect(engine.high_surprise_beliefs).to be_empty
    end

    it 'returns surprised beliefs' do
      b = engine.add_belief(content: 'shock', prediction: { v: 1.0 }, precision: 0.9)
      engine.observe(belief_id: b.id, observation: { v: 0.0 })
      expect(engine.high_surprise_beliefs.size).to eq(1)
    end
  end

  describe '#domain_free_energy' do
    it 'returns zero for empty domain' do
      expect(engine.domain_free_energy(domain: :test)).to eq(0.0)
    end

    it 'computes free energy for domain only' do
      b_env = engine.add_belief(content: 'env', domain: :environment, prediction: { v: 1.0 }, precision: 0.9)
      engine.add_belief(content: 'social', domain: :social, prediction: { v: 1.0 }, precision: 0.9)
      engine.observe(belief_id: b_env.id, observation: { v: 0.0 })
      expect(engine.domain_free_energy(domain: :environment)).to be > 0.0
    end
  end

  describe '#most_surprising' do
    it 'returns beliefs sorted by free energy descending' do
      high = engine.add_belief(content: 'a', prediction: { v: 1.0 }, precision: 0.9)
      low  = engine.add_belief(content: 'b', prediction: { v: 0.5 }, precision: 0.3)
      engine.observe(belief_id: high.id, observation: { v: 0.0 })
      engine.observe(belief_id: low.id, observation: { v: 0.0 })

      result = engine.most_surprising(limit: 2)
      expect(result.first[:free_energy]).to be >= result.last[:free_energy]
    end
  end

  describe '#most_precise' do
    it 'returns beliefs sorted by precision descending' do
      engine.add_belief(content: 'low', precision: 0.2)
      engine.add_belief(content: 'high', precision: 0.8)

      result = engine.most_precise(limit: 2)
      expect(result.first[:precision]).to be >= result.last[:precision]
    end
  end

  describe '#decay_stale' do
    it 'decays precision of stale beliefs' do
      b = engine.add_belief(content: 'old', precision: 0.8)
      allow(Time).to receive(:now).and_return(Time.now.utc + 200)
      original = b.precision
      engine.decay_stale
      expect(b.precision).not_to eq(original)
    end
  end

  describe '#remove_belief' do
    it 'removes a belief' do
      b = engine.add_belief(content: 'temporary')
      engine.remove_belief(belief_id: b.id)
      expect(engine.beliefs).to be_empty
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      h = engine.to_h
      expect(h).to include(
        :belief_count, :total_free_energy, :surprise_level,
        :high_surprise_count, :mean_precision, :history_size
      )
    end
  end
end
