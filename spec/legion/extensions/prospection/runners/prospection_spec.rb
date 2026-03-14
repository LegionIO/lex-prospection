# frozen_string_literal: true

RSpec.describe Legion::Extensions::Prospection::Runners::Prospection do
  let(:client) { Legion::Extensions::Prospection::Client.new }

  let(:base_params) do
    {
      domain:            :career,
      description:       'Land a new job',
      time_horizon:      60,
      predicted_valence: 0.8,
      predicted_arousal: 0.6,
      confidence:        0.5
    }
  end

  describe '#imagine_future' do
    it 'returns success with scenario data' do
      result = client.imagine_future(**base_params)
      expect(result[:success]).to be true
      expect(result[:scenario_id]).to be_a(String)
      expect(result[:domain]).to eq(:career)
      expect(result[:label]).to be_a(Symbol)
      expect(result[:corrected_valence]).to be_a(Float)
      expect(result[:corrected_arousal]).to be_a(Float)
      expect(result[:confidence]).to be_a(Float)
      expect(result[:confidence_label]).to be_a(Symbol)
    end

    it 'corrected_valence is less than raw predicted for positive values' do
      result = client.imagine_future(**base_params)
      expect(result[:corrected_valence]).to be < base_params[:predicted_valence]
    end
  end

  describe '#resolve_future' do
    let!(:scenario_id) { client.imagine_future(**base_params)[:scenario_id] }

    it 'returns success with forecast_error' do
      result = client.resolve_future(
        scenario_id:    scenario_id,
        actual_valence: 0.5,
        actual_arousal: 0.4
      )
      expect(result[:success]).to be true
      expect(result[:forecast_error]).to be_a(Float)
    end

    it 'returns failure for unknown id' do
      result = client.resolve_future(
        scenario_id:    'no-such-id',
        actual_valence: 0.5,
        actual_arousal: 0.4
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns failure when already resolved' do
      client.resolve_future(scenario_id: scenario_id, actual_valence: 0.5, actual_arousal: 0.4)
      result = client.resolve_future(scenario_id: scenario_id, actual_valence: 0.8, actual_arousal: 0.3)
      expect(result[:success]).to be false
    end
  end

  describe '#forecast_accuracy' do
    it 'returns accuracy for a domain' do
      result = client.forecast_accuracy(domain: :career)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:career)
      expect(result[:accuracy]).to be_a(Float)
    end

    it 'defaults domain to :general' do
      result = client.forecast_accuracy
      expect(result[:domain]).to eq(:general)
    end

    it 'returns 1.0 accuracy for domain with no resolutions' do
      result = client.forecast_accuracy(domain: :untracked)
      expect(result[:accuracy]).to eq(1.0)
    end
  end

  describe '#near_future_scenarios' do
    before do
      client.imagine_future(**base_params, time_horizon: 3, description: 'near')
      client.imagine_future(**base_params, time_horizon: 90, description: 'far')
    end

    it 'returns scenarios within days window' do
      result = client.near_future_scenarios(days: 7)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:scenarios].first[:description]).to eq('near')
    end

    it 'returns empty when no scenarios in window' do
      result = client.near_future_scenarios(days: 1)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#vivid_scenarios' do
    before { 3.times { |i| client.imagine_future(**base_params, description: "s#{i}") } }

    it 'returns scenarios sorted by vividness' do
      result = client.vivid_scenarios(count: 2)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
      expect(result[:scenarios]).to all(have_key(:vividness))
    end
  end

  describe '#scenarios_in_domain' do
    before do
      client.imagine_future(**base_params)
      client.imagine_future(**base_params, domain: :health, description: 'health scenario')
    end

    it 'returns scenarios for the specified domain' do
      result = client.scenarios_in_domain(domain: :career)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:career)
      expect(result[:count]).to eq(1)
    end

    it 'returns empty for unknown domain' do
      result = client.scenarios_in_domain(domain: :unknown)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#update_prospection' do
    before { client.imagine_future(**base_params) }

    it 'decays scenarios and returns stats' do
      result = client.update_prospection
      expect(result[:success]).to be true
      expect(result[:scenario_count]).to be_a(Integer)
      expect(result[:domain_count]).to be_a(Integer)
      expect(result[:history_size]).to be_a(Integer)
    end
  end

  describe '#prospection_stats' do
    it 'returns success and stats hash' do
      result = client.prospection_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to have_key(:scenario_count)
      expect(result[:stats]).to have_key(:domain_count)
      expect(result[:stats]).to have_key(:history_size)
      expect(result[:stats]).to have_key(:domain_accuracy)
    end
  end
end
