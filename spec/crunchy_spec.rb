require 'spec_helper'

describe Crunchy do
  it 'should have a version number' do
    expect(Crunchy::VERSION).not_to be nil
  end

  describe '.derive_name' do
    before do
      stub_const('SomeIndex', Class.new)

      stub_index(:developers)

      stub_index('namespace/autocomplete')
    end

    specify do
      expect { described_class.derive_name('some') }
        .to raise_error(Crunchy::UndefinedIndex, /SomeIndex/)
    end
    specify do
      expect { described_class.derive_name('borogoves') }
        .to raise_error(Crunchy::UndefinedIndex, /Borogoves/)
    end

    specify { expect(described_class.derive_name(DevelopersIndex)).to eq(DevelopersIndex) }
    specify { expect(described_class.derive_name('developers_index')).to eq(DevelopersIndex) }
    specify { expect(described_class.derive_name('developers')).to eq(DevelopersIndex) }
    specify do
      expect(described_class.derive_name('namespace/autocomplete')).to eq(Namespace::AutocompleteIndex)
    end
  end

  describe '.massacre' do
    before { Crunchy.massacre }

    before do
      allow(Crunchy).to receive_messages(configuration: Crunchy.configuration.merge(prefix: 'prefix1'))
      stub_index(:admins).create!
      allow(Crunchy).to receive_messages(configuration: Crunchy.configuration.merge(prefix: 'prefix2'))
      stub_index(:developers).create!

      Crunchy.massacre

      allow(Crunchy).to receive_messages(configuration: Crunchy.configuration.merge(prefix: 'prefix1'))
    end

    specify { expect(AdminsIndex.exists?).to eq(true) }
    specify { expect(DevelopersIndex.exists?).to eq(false) }
  end

  describe '.client' do
    let!(:initial_client) { Crunchy.current[:Crunchy_client] }
    let(:faraday_block) { proc {} }
    let(:mock_client) { double(:client) }
    let(:expected_client_config) { {transport_options: {}} }

    before do
      Crunchy.current[:Crunchy_client] = nil
      allow(Crunchy).to receive_messages(configuration: {transport_options: {proc: faraday_block}})

      allow(::Elasticsearch::Client).to receive(:new).with(expected_client_config) do |*_args, &passed_block|
        # RSpec's `with(..., &block)` was used previously, but doesn't actually do
        # any verification of the passed block (even of its presence).
        expect(passed_block.source_location).to eq(faraday_block.source_location)

        mock_client
      end
    end

    its(:client) { is_expected.to eq(mock_client) }

    after { Crunchy.current[:Crunchy_client] = initial_client }
  end

  describe '.create_indices' do
    before do
      stub_index(:cities)
      stub_index(:places)

      # To avoid flaky issues when previous specs were run
      allow(Crunchy::Index).to receive(:descendants).and_return([CitiesIndex, PlacesIndex])

      Crunchy.massacre
    end

    specify do
      expect(CitiesIndex.exists?).to eq false
      expect(PlacesIndex.exists?).to eq false

      CitiesIndex.create!

      expect(CitiesIndex.exists?).to eq true
      expect(PlacesIndex.exists?).to eq false

      expect { Crunchy.create_indices }.not_to raise_error

      expect(CitiesIndex.exists?).to eq true
      expect(PlacesIndex.exists?).to eq true
    end

    specify '.create_indices!' do
      expect(CitiesIndex.exists?).to eq false
      expect(PlacesIndex.exists?).to eq false

      expect { Crunchy.create_indices! }.not_to raise_error

      expect(CitiesIndex.exists?).to eq true
      expect(PlacesIndex.exists?).to eq true

      expect { Crunchy.create_indices! }.to raise_error(Elasticsearch::Transport::Transport::Errors::BadRequest)
    end
  end
end
