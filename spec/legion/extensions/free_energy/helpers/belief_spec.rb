# frozen_string_literal: true

RSpec.describe Legion::Extensions::FreeEnergy::Helpers::Belief do
  subject(:belief) do
    described_class.new(
      id:         :belief_one,
      content:    'weather model',
      domain:     :environment,
      prediction: { temperature: 0.7, humidity: 0.5 },
      precision:  0.6
    )
  end

  describe '#initialize' do
    it 'sets id' do
      expect(belief.id).to eq(:belief_one)
    end

    it 'sets content' do
      expect(belief.content).to eq('weather model')
    end

    it 'sets domain' do
      expect(belief.domain).to eq(:environment)
    end

    it 'sets prediction' do
      expect(belief.prediction).to eq({ temperature: 0.7, humidity: 0.5 })
    end

    it 'sets precision' do
      expect(belief.precision).to eq(0.6)
    end

    it 'clamps precision to ceiling' do
      b = described_class.new(id: :x, content: 'test', precision: 1.5)
      expect(b.precision).to eq(Legion::Extensions::FreeEnergy::Helpers::Constants::PRECISION_CEILING)
    end

    it 'clamps precision to floor' do
      b = described_class.new(id: :x, content: 'test', precision: -0.5)
      expect(b.precision).to eq(Legion::Extensions::FreeEnergy::Helpers::Constants::PRECISION_FLOOR)
    end

    it 'starts with zero prediction error' do
      expect(belief.prediction_error).to eq(0.0)
    end

    it 'starts with nil last_observation' do
      expect(belief.last_observation).to be_nil
    end

    it 'is not surprising initially' do
      expect(belief.surprising?).to be false
    end
  end

  describe '#observe' do
    it 'sets last_observation' do
      belief.observe(observation: { temperature: 0.7, humidity: 0.5 })
      expect(belief.last_observation).to eq({ temperature: 0.7, humidity: 0.5 })
    end

    it 'computes low error for matching observation' do
      belief.observe(observation: { temperature: 0.7, humidity: 0.5 })
      expect(belief.prediction_error).to eq(0.0)
    end

    it 'computes high error for divergent observation' do
      belief.observe(observation: { temperature: 0.0, humidity: 0.0 })
      expect(belief.prediction_error).to be > 0.3
    end

    it 'updates precision upward on low error' do
      original = belief.precision
      belief.observe(observation: { temperature: 0.7, humidity: 0.5 })
      expect(belief.precision).to be > original
    end

    it 'updates precision downward on high error' do
      original = belief.precision
      belief.observe(observation: { temperature: 0.0, humidity: 0.0 })
      expect(belief.precision).to be < original
    end

    it 'returns self for chaining' do
      expect(belief.observe(observation: {})).to be(belief)
    end

    it 'updates updated_at' do
      before = belief.updated_at
      sleep 0.01
      belief.observe(observation: { temperature: 0.5 })
      expect(belief.updated_at).to be > before
    end
  end

  describe '#free_energy' do
    it 'returns zero when no observation made' do
      expect(belief.free_energy).to eq(0.0)
    end

    it 'returns precision-weighted prediction error' do
      belief.observe(observation: { temperature: 0.0, humidity: 0.0 })
      expect(belief.free_energy).to be > 0.0
    end

    it 'is higher when precision is higher' do
      high_prec = described_class.new(id: :hp, content: 'test', prediction: { v: 0.9 }, precision: 0.9)
      low_prec  = described_class.new(id: :lp, content: 'test', prediction: { v: 0.9 }, precision: 0.2)

      high_prec.observe(observation: { v: 0.0 })
      low_prec.observe(observation: { v: 0.0 })

      expect(high_prec.free_energy).to be > low_prec.free_energy
    end
  end

  describe '#surprise_label' do
    it 'returns :trivial when no error' do
      expect(belief.surprise_label).to eq(:trivial)
    end

    it 'returns non-trivial label for larger errors' do
      belief.observe(observation: { temperature: 0.0, humidity: 0.0 })
      expect(belief.surprise_label).not_to eq(:trivial)
    end
  end

  describe '#revise_prediction' do
    it 'moves prediction toward observation' do
      belief.observe(observation: { temperature: 1.0, humidity: 0.5 })
      belief.revise_prediction(observation: { temperature: 1.0 })
      expect(belief.prediction[:temperature]).to be > 0.7
    end

    it 'preserves unobserved prediction keys' do
      belief.revise_prediction(observation: { temperature: 1.0 })
      expect(belief.prediction[:humidity]).to eq(0.5)
    end

    it 'replaces non-numeric values' do
      b = described_class.new(id: :x, content: 'test', prediction: { color: :red })
      b.revise_prediction(observation: { color: :blue })
      expect(b.prediction[:color]).to eq(:blue)
    end
  end

  describe '#stale?' do
    it 'is not stale immediately' do
      expect(belief.stale?).to be false
    end

    it 'is stale after threshold' do
      future = Time.now.utc + 200
      expect(belief.stale?(now: future)).to be true
    end
  end

  describe '#decay_precision' do
    it 'moves precision toward default' do
      belief.decay_precision
      expect(belief.precision).to be < 0.6
    end

    it 'moves low precision toward default' do
      b = described_class.new(id: :x, content: 'test', precision: 0.2)
      b.decay_precision
      expect(b.precision).to be > 0.2
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = belief.to_h
      expect(h).to include(
        :id, :domain, :content, :prediction, :last_observation,
        :prediction_error, :precision, :free_energy, :surprise_label,
        :surprising, :created_at, :updated_at
      )
    end
  end
end
