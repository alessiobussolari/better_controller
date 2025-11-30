# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Configuration do
  let(:config) { BetterController.config }

  before do
    BetterController.reset_config!
  end

  after do
    BetterController.reset_config!
  end

  describe 'instance creation' do
    it 'returns a Configuration instance' do
      expect(config).to be_a(described_class)
    end
  end

  describe '#pagination' do
    it 'returns pagination configuration' do
      expect(config.pagination[:enabled]).to be true
      expect(config.pagination[:per_page]).to eq(25)
    end
  end

  describe '#serialization' do
    it 'returns serialization configuration' do
      expect(config.serialization[:include_root]).to be false
      expect(config.serialization[:camelize_keys]).to be true
    end
  end

  describe '#error_handling' do
    it 'returns error handling configuration' do
      expect(config.error_handling[:log_errors]).to be true
      expect(config.error_handling[:detailed_errors]).to be true
    end
  end

  describe '#html' do
    it 'returns HTML configuration' do
      expect(config.html[:page_component_namespace]).to eq('Templates')
      expect(config.html[:flash_partial]).to eq('shared/flash')
      expect(config.html[:form_errors_partial]).to eq('shared/form_errors')
    end
  end

  describe '#turbo' do
    it 'returns Turbo configuration' do
      expect(config.turbo[:enabled]).to be true
      expect(config.turbo[:auto_flash]).to be true
      expect(config.turbo[:auto_form_errors]).to be true
    end
  end

  describe '#page_component_namespace' do
    it 'returns the page component namespace' do
      expect(config.page_component_namespace).to eq('Templates')
    end
  end

  describe '#flash_partial' do
    it 'returns the flash partial path' do
      expect(config.flash_partial).to eq('shared/flash')
    end
  end

  describe '#form_errors_partial' do
    it 'returns the form errors partial path' do
      expect(config.form_errors_partial).to eq('shared/form_errors')
    end
  end

  describe '#turbo_enabled?' do
    it 'returns whether turbo is enabled' do
      expect(config.turbo_enabled?).to be true
    end
  end

  describe 'BetterController.configure' do
    it 'allows modifying configuration via block' do
      BetterController.configure do |c|
        c.html_page_component_namespace = 'Components'
      end

      expect(config.page_component_namespace).to eq('Components')
    end
  end

  describe 'BetterController.reset_config!' do
    it 'resets configuration to defaults' do
      BetterController.configure do |c|
        c.html_page_component_namespace = 'Custom'
      end

      BetterController.reset_config!

      expect(BetterController.config.page_component_namespace).to eq('Templates')
    end
  end

  describe '[] accessor' do
    it 'allows accessing options by key' do
      expect(config[:pagination]).to be_a(Hash)
      expect(config[:html]).to be_a(Hash)
    end
  end

  describe '[]= accessor' do
    it 'allows setting options by key' do
      config[:html] = { page_component_namespace: 'Custom' }

      expect(config.html_page_component_namespace).to eq('Custom')
    end

    context 'with :pagination key' do
      it 'sets pagination_enabled when provided' do
        config[:pagination] = { enabled: false }

        expect(config.pagination_enabled).to be false
      end

      it 'sets pagination_per_page when provided' do
        config[:pagination] = { per_page: 100 }

        expect(config.pagination_per_page).to eq(100)
      end

      it 'sets both pagination options at once' do
        config[:pagination] = { enabled: false, per_page: 50 }

        expect(config.pagination_enabled).to be false
        expect(config.pagination_per_page).to eq(50)
      end
    end

    context 'with :serialization key' do
      it 'sets serialization_include_root when provided' do
        config[:serialization] = { include_root: true }

        expect(config.serialization_include_root).to be true
      end

      it 'sets serialization_camelize_keys when provided' do
        config[:serialization] = { camelize_keys: false }

        expect(config.serialization_camelize_keys).to be false
      end
    end

    context 'with :error_handling key' do
      it 'sets error_handling_log_errors when provided' do
        config[:error_handling] = { log_errors: false }

        expect(config.error_handling_log_errors).to be false
      end

      it 'sets error_handling_detailed_errors when provided' do
        config[:error_handling] = { detailed_errors: false }

        expect(config.error_handling_detailed_errors).to be false
      end
    end

    context 'with :turbo key' do
      it 'sets turbo_enabled when provided' do
        config[:turbo] = { enabled: false }

        expect(config.turbo_enabled).to be false
      end

      it 'sets turbo_default_frame when provided' do
        config[:turbo] = { default_frame: 'modal' }

        expect(config.turbo_default_frame).to eq('modal')
      end

      it 'sets turbo_auto_flash when provided' do
        config[:turbo] = { auto_flash: false }

        expect(config.turbo_auto_flash).to be false
      end

      it 'sets turbo_auto_form_errors when provided' do
        config[:turbo] = { auto_form_errors: false }

        expect(config.turbo_auto_form_errors).to be false
      end
    end
  end

  describe '#to_h' do
    it 'returns configuration as a hash' do
      expect(config.to_h).to be_a(Hash)
      expect(config.to_h[:pagination]).to be_present
      expect(config.to_h[:serialization]).to be_present
      expect(config.to_h[:error_handling]).to be_present
      expect(config.to_h[:html]).to be_present
      expect(config.to_h[:turbo]).to be_present
      expect(config.to_h[:wrapped_responses]).to be_present
    end
  end

  describe '#wrapped_responses_class' do
    it 'defaults to nil' do
      expect(config.wrapped_responses_class).to be_nil
    end

    it 'can be set to BetterController::Result' do
      config.wrapped_responses_class = BetterController::Result
      expect(config.wrapped_responses_class).to eq(BetterController::Result)
    end
  end

  describe '#wrapped_responses_enabled?' do
    it 'returns false when wrapped_responses_class is nil' do
      expect(config.wrapped_responses_enabled?).to be false
    end

    it 'returns true when wrapped_responses_class is set' do
      config.wrapped_responses_class = BetterController::Result
      expect(config.wrapped_responses_enabled?).to be true
    end
  end

  describe '#api_version' do
    it 'defaults to v1' do
      expect(config.api_version).to eq('v1')
    end

    it 'can be set to a custom value' do
      config.api_version = 'v2'
      expect(config.api_version).to eq('v2')
    end
  end

  describe 'direct attribute access (Kaminari-style)' do
    it 'allows direct setting and getting of pagination_enabled' do
      config.pagination_enabled = false
      expect(config.pagination_enabled).to be false
    end

    it 'allows direct setting and getting of pagination_per_page' do
      config.pagination_per_page = 50
      expect(config.pagination_per_page).to eq(50)
    end

    it 'allows direct setting and getting of serialization_include_root' do
      config.serialization_include_root = true
      expect(config.serialization_include_root).to be true
    end

    it 'allows direct setting and getting of turbo_enabled' do
      config.turbo_enabled = false
      expect(config.turbo_enabled).to be false
    end
  end
end
