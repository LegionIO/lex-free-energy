# frozen_string_literal: true

RSpec.describe Legion::Extensions::FreeEnergy::Client do
  subject(:client) { described_class.new }

  describe '#add_generative_belief' do
    it 'delegates to runner' do
      result = client.add_generative_belief(content: 'test model')
      expect(result[:success]).to be true
    end
  end

  describe '#observe_outcome' do
    it 'observes and computes error' do
      belief = client.add_generative_belief(content: 'model', prediction: { v: 0.5 })
      result = client.observe_outcome(belief_id: belief[:belief_id], observation: { v: 0.5 })
      expect(result[:prediction_error]).to eq(0.0)
    end
  end

  describe '#minimize_free_energy' do
    it 'performs perceptual minimization' do
      belief = client.add_generative_belief(content: 'model', prediction: { v: 0.3 })
      client.observe_outcome(belief_id: belief[:belief_id], observation: { v: 0.9 })
      result = client.minimize_free_energy(belief_id: belief[:belief_id], mode: :perceptual)
      expect(result[:success]).to be true
    end
  end

  describe '#free_energy_stats' do
    it 'returns stats' do
      result = client.free_energy_stats
      expect(result[:success]).to be true
      expect(result[:belief_count]).to eq(0)
    end
  end

  describe 'with injected engine' do
    it 'uses the provided engine' do
      engine = Legion::Extensions::FreeEnergy::Helpers::FreeEnergyEngine.new
      engine.add_belief(content: 'preloaded')
      custom_client = described_class.new(engine: engine)
      expect(custom_client.free_energy_stats[:belief_count]).to eq(1)
    end
  end
end
