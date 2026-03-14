# frozen_string_literal: true

RSpec.describe Legion::Extensions::Prospection::Helpers::ProspectionEngine do
  let(:engine)    { described_class.new }
  let(:constants) { Legion::Extensions::Prospection::Helpers::Constants }

  let(:scenario_params) do
    {
      domain:            :career,
      description:       'Get a raise',
      time_horizon:      30,
      predicted_valence: 0.7,
      predicted_arousal: 0.6,
      confidence:        0.5
    }
  end

  describe '#imagine' do
    it 'creates and returns a Scenario' do
      s = engine.imagine(**scenario_params)
      expect(s).to be_a(Legion::Extensions::Prospection::Helpers::Scenario)
    end

    it 'stores the scenario' do
      s = engine.imagine(**scenario_params)
      expect(engine.scenarios[s.id]).to eq(s)
    end

    it 'applies focalism discount when domain already has active scenarios' do
      first = engine.imagine(**scenario_params)
      first_valence = first.predicted_valence

      second = engine.imagine(**scenario_params, description: 'Another raise')
      expect(second.predicted_valence).to be < first_valence
    end

    it 'does not apply focalism for first scenario in domain' do
      s = engine.imagine(**scenario_params)
      expected = 0.7
      expect(s.predicted_valence).to eq(expected)
    end
  end

  describe '#scenarios_for' do
    it 'returns active scenarios in domain' do
      engine.imagine(**scenario_params)
      engine.imagine(**scenario_params, domain: :health)
      results = engine.scenarios_for(domain: :career)
      expect(results.size).to eq(1)
      expect(results.first.domain).to eq(:career)
    end

    it 'excludes resolved scenarios' do
      s = engine.imagine(**scenario_params)
      engine.resolve_scenario(id: s.id, actual_valence: 0.5, actual_arousal: 0.4)
      expect(engine.scenarios_for(domain: :career)).to be_empty
    end
  end

  describe '#resolve_scenario' do
    let!(:scenario) { engine.imagine(**scenario_params) }

    it 'marks the scenario as resolved' do
      engine.resolve_scenario(id: scenario.id, actual_valence: 0.6, actual_arousal: 0.4)
      expect(scenario.resolved?).to be true
    end

    it 'returns the resolved scenario' do
      result = engine.resolve_scenario(id: scenario.id, actual_valence: 0.6, actual_arousal: 0.4)
      expect(result).to eq(scenario)
    end

    it 'returns nil for unknown id' do
      result = engine.resolve_scenario(id: 'no-such-id', actual_valence: 0.5, actual_arousal: 0.5)
      expect(result).to be_nil
    end

    it 'returns nil if already resolved' do
      engine.resolve_scenario(id: scenario.id, actual_valence: 0.5, actual_arousal: 0.5)
      result = engine.resolve_scenario(id: scenario.id, actual_valence: 0.8, actual_arousal: 0.3)
      expect(result).to be_nil
    end

    it 'updates domain accuracy' do
      engine.resolve_scenario(id: scenario.id, actual_valence: 0.6, actual_arousal: 0.4)
      expect(engine.domain_accuracy).to have_key(:career)
    end

    it 'appends to history' do
      engine.resolve_scenario(id: scenario.id, actual_valence: 0.6, actual_arousal: 0.4)
      expect(engine.history.size).to eq(1)
    end
  end

  describe '#accuracy_for' do
    it 'returns 1.0 for domain with no resolutions' do
      expect(engine.accuracy_for(:unknown)).to eq(1.0)
    end

    it 'returns a float between 0 and 1 after resolution' do
      s = engine.imagine(**scenario_params)
      engine.resolve_scenario(id: s.id, actual_valence: 0.6, actual_arousal: 0.4)
      acc = engine.accuracy_for(:career)
      expect(acc).to be_between(0.0, 1.0)
    end
  end

  describe '#near_future' do
    it 'returns scenarios within time horizon' do
      engine.imagine(**scenario_params, time_horizon: 5)
      engine.imagine(**scenario_params, time_horizon: 60, description: 'far future')
      near = engine.near_future(days: 7)
      expect(near.size).to eq(1)
      expect(near.first.time_horizon).to eq(5)
    end

    it 'excludes resolved scenarios' do
      s = engine.imagine(**scenario_params, time_horizon: 3)
      engine.resolve_scenario(id: s.id, actual_valence: 0.4, actual_arousal: 0.3)
      expect(engine.near_future(days: 7)).to be_empty
    end
  end

  describe '#most_vivid' do
    it 'returns up to count unresolved scenarios sorted by vividness' do
      3.times { |i| engine.imagine(**scenario_params, description: "scenario #{i}") }
      vivid = engine.most_vivid(count: 2)
      expect(vivid.size).to eq(2)
    end

    it 'excludes resolved scenarios' do
      s = engine.imagine(**scenario_params)
      engine.resolve_scenario(id: s.id, actual_valence: 0.5, actual_arousal: 0.4)
      expect(engine.most_vivid(count: 5)).to be_empty
    end
  end

  describe '#decay_all' do
    it 'decays all scenarios' do
      engine.imagine(**scenario_params)
      initial_confidence = engine.scenarios.values.first.confidence
      engine.decay_all
      expect(engine.scenarios.values.first.confidence).to be < initial_confidence
    end

    it 'prunes expired scenarios' do
      engine.imagine(**scenario_params)
      1000.times { engine.decay_all }
      expect(engine.scenario_count).to eq(0)
    end
  end

  describe '#remove_scenario' do
    it 'removes the scenario by id' do
      s = engine.imagine(**scenario_params)
      engine.remove_scenario(id: s.id)
      expect(engine.scenarios[s.id]).to be_nil
    end
  end

  describe '#scenario_count' do
    it 'returns total stored scenario count' do
      expect(engine.scenario_count).to eq(0)
      engine.imagine(**scenario_params)
      expect(engine.scenario_count).to eq(1)
    end
  end

  describe '#domain_count' do
    it 'returns count of unique domains' do
      engine.imagine(**scenario_params)
      engine.imagine(**scenario_params, domain: :health)
      expect(engine.domain_count).to eq(2)
    end
  end

  describe 'capacity limit' do
    it 'prunes oldest when at MAX_SCENARIOS' do
      constants::MAX_SCENARIOS.times do |i|
        engine.imagine(**scenario_params, description: "s#{i}")
      end
      expect(engine.scenario_count).to eq(constants::MAX_SCENARIOS)
      engine.imagine(**scenario_params, description: 'overflow')
      expect(engine.scenario_count).to eq(constants::MAX_SCENARIOS)
    end
  end

  describe '#to_h' do
    it 'contains expected keys' do
      h = engine.to_h
      expect(h).to have_key(:scenario_count)
      expect(h).to have_key(:domain_count)
      expect(h).to have_key(:history_size)
      expect(h).to have_key(:domain_accuracy)
    end
  end
end
