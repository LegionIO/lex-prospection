# frozen_string_literal: true

RSpec.describe Legion::Extensions::Prospection::Client do
  let(:client) { described_class.new }

  it 'can be instantiated' do
    expect(client).to be_a(described_class)
  end

  it 'includes all runner methods' do
    expect(client).to respond_to(:imagine_future)
    expect(client).to respond_to(:resolve_future)
    expect(client).to respond_to(:forecast_accuracy)
    expect(client).to respond_to(:near_future_scenarios)
    expect(client).to respond_to(:vivid_scenarios)
    expect(client).to respond_to(:scenarios_in_domain)
    expect(client).to respond_to(:update_prospection)
    expect(client).to respond_to(:prospection_stats)
  end

  it 'exposes the prospection engine' do
    expect(client.prospection_engine).to be_a(Legion::Extensions::Prospection::Helpers::ProspectionEngine)
  end

  it 'accepts an injected prospection engine' do
    engine = Legion::Extensions::Prospection::Helpers::ProspectionEngine.new
    c = described_class.new(prospection_engine: engine)
    expect(c.prospection_engine).to be(engine)
  end

  describe 'full lifecycle' do
    it 'imagines, tracks, resolves, and calibrates affective forecasts' do
      # Imagine a future scenario
      imagine_result = client.imagine_future(
        domain:            :career,
        description:       'Present at a major conference',
        time_horizon:      45,
        predicted_valence: 0.9,
        predicted_arousal: 0.8,
        confidence:        0.6
      )
      expect(imagine_result[:success]).to be true
      scenario_id = imagine_result[:scenario_id]

      # Corrected values are lower than raw predicted
      expect(imagine_result[:corrected_valence]).to be < 0.9
      expect(imagine_result[:corrected_arousal]).to be < 0.8

      # Near-future scenarios not visible at 7-day window
      near = client.near_future_scenarios(days: 7)
      expect(near[:count]).to eq(0)

      # Near-future visible at 50-day window
      near50 = client.near_future_scenarios(days: 50)
      expect(near50[:count]).to eq(1)

      # Vivid scenarios includes our scenario
      vivid = client.vivid_scenarios(count: 5)
      expect(vivid[:count]).to eq(1)

      # Domain-scoped listing
      domain_result = client.scenarios_in_domain(domain: :career)
      expect(domain_result[:count]).to eq(1)

      # Accuracy starts at 1.0 (no resolutions yet)
      acc_before = client.forecast_accuracy(domain: :career)
      expect(acc_before[:accuracy]).to eq(1.0)

      # Resolve the scenario - actual lower than predicted (typical impact bias)
      resolve_result = client.resolve_future(
        scenario_id:    scenario_id,
        actual_valence: 0.5,
        actual_arousal: 0.4
      )
      expect(resolve_result[:success]).to be true
      expect(resolve_result[:forecast_error]).to be_a(Float)

      # Domain-scoped listing now empty (scenario resolved)
      domain_after = client.scenarios_in_domain(domain: :career)
      expect(domain_after[:count]).to eq(0)

      # Accuracy updated
      acc_after = client.forecast_accuracy(domain: :career)
      expect(acc_after[:accuracy]).to be_a(Float)

      # Imagine a second scenario (focalism discount applies with resolved but check another fresh)
      client.imagine_future(
        domain:            :career,
        description:       'Get team lead title',
        time_horizon:      180,
        predicted_valence: 0.75,
        predicted_arousal: 0.65,
        confidence:        0.45
      )

      # Tick decay — resolved scenario stays stored until it expires via decay
      tick_result = client.update_prospection
      expect(tick_result[:success]).to be true
      expect(tick_result[:scenario_count]).to eq(2)

      # Stats
      stats = client.prospection_stats[:stats]
      expect(stats[:scenario_count]).to eq(2)
      expect(stats[:history_size]).to eq(1)
    end
  end
end
