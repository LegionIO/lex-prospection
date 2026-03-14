# frozen_string_literal: true

RSpec.describe Legion::Extensions::Prospection::Helpers::Scenario do
  let(:constants) { Legion::Extensions::Prospection::Helpers::Constants }

  let(:scenario) do
    described_class.new(
      domain:            :career,
      description:       'Get promoted to senior engineer',
      time_horizon:      90,
      predicted_valence: 0.8,
      predicted_arousal: 0.7,
      confidence:        0.5
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(scenario.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'clamps predicted_valence to -1..1' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 10,
        predicted_valence: 2.0, predicted_arousal: 0.5
      )
      expect(s.predicted_valence).to eq(1.0)
    end

    it 'clamps predicted_arousal to 0..1' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 10,
        predicted_valence: 0.5, predicted_arousal: -0.5
      )
      expect(s.predicted_arousal).to eq(0.0)
    end

    it 'caps time_horizon at MAX_TIME_HORIZON' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 1000,
        predicted_valence: 0.5, predicted_arousal: 0.5
      )
      expect(s.time_horizon).to eq(constants::MAX_TIME_HORIZON)
    end

    it 'uses DEFAULT_CONFIDENCE when confidence not provided' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 10,
        predicted_valence: 0.5, predicted_arousal: 0.5
      )
      expect(s.confidence).to eq(constants::DEFAULT_CONFIDENCE)
    end

    it 'uses DEFAULT_VIVIDNESS' do
      expect(scenario.vividness).to eq(constants::DEFAULT_VIVIDNESS)
    end

    it 'is not resolved initially' do
      expect(scenario.resolved?).to be false
    end
  end

  describe '#temporal_discount' do
    it 'returns a value between 0 and 1' do
      expect(scenario.temporal_discount).to be_between(0.0, 1.0)
    end

    it 'gives nearer futures a higher discount factor' do
      near = described_class.new(
        domain: :test, description: 'x', time_horizon: 5,
        predicted_valence: 0.8, predicted_arousal: 0.5
      )
      far = described_class.new(
        domain: :test, description: 'x', time_horizon: 100,
        predicted_valence: 0.8, predicted_arousal: 0.5
      )
      expect(near.temporal_discount).to be > far.temporal_discount
    end
  end

  describe '#corrected_valence' do
    it 'applies impact bias correction and temporal discount' do
      expect(scenario.corrected_valence).to be < scenario.predicted_valence
    end

    it 'is less than or equal to predicted_valence in magnitude for positive values' do
      expect(scenario.corrected_valence.abs).to be <= scenario.predicted_valence.abs
    end
  end

  describe '#corrected_arousal' do
    it 'is reduced from predicted_arousal' do
      expect(scenario.corrected_arousal).to be < scenario.predicted_arousal
    end
  end

  describe '#label' do
    it 'returns a symbol' do
      expect(scenario.label).to be_a(Symbol)
    end

    it 'returns :positive for high corrected valence' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 0,
        predicted_valence: 1.0, predicted_arousal: 0.5
      )
      expect(s.label).to eq(:positive)
    end

    it 'returns :negative for very negative corrected valence' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 1,
        predicted_valence: -1.0, predicted_arousal: 0.5
      )
      expect(s.label).to eq(:negative)
    end

    it 'returns :ambivalent for near-zero corrected valence' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 1,
        predicted_valence: 0.0, predicted_arousal: 0.5
      )
      expect(s.label).to eq(:ambivalent)
    end
  end

  describe '#confidence_label' do
    it 'returns a symbol' do
      expect(scenario.confidence_label).to be_a(Symbol)
    end

    it 'returns :calibrated for high confidence' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 10,
        predicted_valence: 0.5, predicted_arousal: 0.5, confidence: 0.9
      )
      expect(s.confidence_label).to eq(:calibrated)
    end

    it 'returns :speculative for low confidence' do
      s = described_class.new(
        domain: :test, description: 'x', time_horizon: 10,
        predicted_valence: 0.5, predicted_arousal: 0.5, confidence: 0.1
      )
      expect(s.confidence_label).to eq(:speculative)
    end
  end

  describe '#decay' do
    it 'reduces confidence' do
      initial_confidence = scenario.confidence
      scenario.decay
      expect(scenario.confidence).to be < initial_confidence
    end

    it 'reduces vividness' do
      initial_vividness = scenario.vividness
      scenario.decay
      expect(scenario.vividness).to be < initial_vividness
    end

    it 'does not drop below 0' do
      1000.times { scenario.decay }
      expect(scenario.confidence).to be >= 0.0
      expect(scenario.vividness).to be >= 0.0
    end
  end

  describe '#reinforce_vividness' do
    it 'increases vividness' do
      initial = scenario.vividness
      scenario.reinforce_vividness(1.0)
      expect(scenario.vividness).to be > initial
    end

    it 'does not exceed 1.0' do
      100.times { scenario.reinforce_vividness(1.0) }
      expect(scenario.vividness).to be <= 1.0
    end
  end

  describe '#apply_focalism_discount' do
    it 'reduces predicted_valence' do
      initial = scenario.predicted_valence
      scenario.apply_focalism_discount
      expect(scenario.predicted_valence.abs).to be < initial.abs
    end

    it 'reduces predicted_arousal' do
      initial = scenario.predicted_arousal
      scenario.apply_focalism_discount
      expect(scenario.predicted_arousal).to be < initial
    end
  end

  describe '#resolve' do
    before { scenario.resolve(actual_valence: 0.6, actual_arousal: 0.5) }

    it 'marks scenario as resolved' do
      expect(scenario.resolved?).to be true
    end

    it 'stores actual_valence' do
      expect(scenario.actual_valence).to eq(0.6)
    end

    it 'stores actual_arousal' do
      expect(scenario.actual_arousal).to eq(0.5)
    end

    it 'sets resolved_at' do
      expect(scenario.resolved_at).to be_a(Time)
    end
  end

  describe '#forecast_error' do
    it 'returns nil when not resolved' do
      expect(scenario.forecast_error).to be_nil
    end

    it 'returns a non-negative float when resolved' do
      scenario.resolve(actual_valence: 0.3, actual_arousal: 0.4)
      expect(scenario.forecast_error).to be_a(Float)
      expect(scenario.forecast_error).to be >= 0.0
    end
  end

  describe '#expired?' do
    it 'returns false for a fresh scenario' do
      expect(scenario.expired?).to be false
    end

    it 'returns true when both confidence and vividness near zero' do
      1000.times { scenario.decay }
      expect(scenario.expired?).to be true
    end
  end

  describe '#to_h' do
    subject(:hash) { scenario.to_h }

    it 'contains all expected keys' do
      expect(hash).to include(
        :id, :domain, :description, :time_horizon,
        :predicted_valence, :predicted_arousal,
        :corrected_valence, :corrected_arousal,
        :confidence, :confidence_label, :vividness,
        :label, :resolved, :forecast_error, :created_at, :resolved_at
      )
    end

    it 'resolved is false for unresolved scenario' do
      expect(hash[:resolved]).to be false
    end

    it 'forecast_error is nil for unresolved scenario' do
      expect(hash[:forecast_error]).to be_nil
    end
  end
end
