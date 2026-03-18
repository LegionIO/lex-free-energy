# frozen_string_literal: true

RSpec.describe Legion::Extensions::FreeEnergy::Runners::FreeEnergy do
  let(:runner_host) do
    Object.new.tap { |o| o.extend(described_class) }
  end

  describe '#add_generative_belief' do
    it 'creates a belief successfully' do
      result = runner_host.add_generative_belief(content: 'test model', domain: :test)
      expect(result[:success]).to be true
      expect(result[:belief_id]).to be_a(Symbol)
    end

    it 'accepts prediction and precision' do
      result = runner_host.add_generative_belief(
        content: 'weather', prediction: { temp: 0.7 }, precision: 0.8
      )
      expect(result[:precision]).to eq(0.8)
    end
  end

  describe '#observe_outcome' do
    let!(:belief_id) do
      runner_host.add_generative_belief(content: 'model', prediction: { v: 0.7 })[:belief_id]
    end

    it 'returns prediction error' do
      result = runner_host.observe_outcome(belief_id: belief_id, observation: { v: 0.7 })
      expect(result[:success]).to be true
      expect(result[:prediction_error]).to eq(0.0)
    end

    it 'detects surprise' do
      result = runner_host.observe_outcome(belief_id: belief_id, observation: { v: 0.0 })
      expect(result[:prediction_error]).to be > 0.0
    end

    it 'returns failure for unknown belief' do
      result = runner_host.observe_outcome(belief_id: :nonexistent, observation: {})
      expect(result[:success]).to be false
    end
  end

  describe '#minimize_free_energy' do
    let!(:belief_id) do
      runner_host.add_generative_belief(content: 'model', prediction: { v: 0.3 })[:belief_id]
    end

    it 'performs perceptual inference' do
      runner_host.observe_outcome(belief_id: belief_id, observation: { v: 0.9 })
      result = runner_host.minimize_free_energy(belief_id: belief_id, mode: :perceptual)
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:perceptual)
    end

    it 'performs active inference' do
      result = runner_host.minimize_free_energy(belief_id: belief_id, mode: :active)
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:active)
      expect(result[:type]).to eq(:active_inference)
    end

    it 'returns failure for unknown belief' do
      result = runner_host.minimize_free_energy(belief_id: :nonexistent)
      expect(result[:success]).to be false
    end

    it 'rejects invalid inference mode' do
      result = runner_host.minimize_free_energy(belief_id: belief_id, mode: :bogus)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_mode)
      expect(result[:valid_modes]).to eq(Legion::Extensions::FreeEnergy::Helpers::Constants::INFERENCE_MODES)
    end
  end

  describe '#compute_free_energy' do
    it 'returns total free energy' do
      result = runner_host.compute_free_energy
      expect(result[:success]).to be true
      expect(result).to include(:total_free_energy, :surprise_level, :high_surprise_count)
    end
  end

  describe '#surprise_assessment' do
    it 'returns surprise assessment' do
      result = runner_host.surprise_assessment
      expect(result[:success]).to be true
      expect(result).to include(:surprise_level, :most_surprising, :most_precise)
    end
  end

  describe '#high_surprise_beliefs' do
    it 'returns empty list when calm' do
      result = runner_host.high_surprise_beliefs
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#domain_free_energy' do
    it 'returns domain-specific free energy' do
      runner_host.add_generative_belief(content: 'env model', domain: :environment)
      result = runner_host.domain_free_energy(domain: :environment)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:environment)
    end
  end

  describe '#update_free_energy' do
    it 'decays stale beliefs and returns stats' do
      result = runner_host.update_free_energy
      expect(result[:success]).to be true
      expect(result).to include(:belief_count, :total_free_energy)
    end
  end

  describe '#free_energy_stats' do
    it 'returns engine statistics' do
      result = runner_host.free_energy_stats
      expect(result[:success]).to be true
      expect(result).to include(:belief_count, :surprise_level)
    end
  end
end
