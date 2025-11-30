# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Dsl::ActionBuilder do
  subject(:builder) { described_class.new(:index, custom_option: true) }

  describe '#initialize' do
    it 'sets the action name' do
      expect(builder.name).to eq(:index)
    end

    it 'initializes config with name and options' do
      expect(builder.config[:name]).to eq(:index)
      expect(builder.config[:options]).to eq({ custom_option: true })
    end

    it 'initializes empty error_handlers' do
      expect(builder.config[:error_handlers]).to eq({})
    end
  end

  describe '#service' do
    it 'sets the service class' do
      builder.service(ExampleService)

      expect(builder.config[:service]).to eq(ExampleService)
    end

    it 'accepts custom method option' do
      builder.service(ExampleService, method: :perform)

      expect(builder.config[:service_method]).to eq(:perform)
    end
  end

  describe '#page' do
    it 'sets the page class' do
      page_class = Class.new
      builder.page(page_class)

      expect(builder.config[:page]).to eq(page_class)
    end
  end

  describe '#component' do
    it 'sets the component class' do
      component_class = Class.new
      builder.component(component_class)

      expect(builder.config[:component]).to eq(component_class)
    end

    it 'accepts default locals' do
      component_class = Class.new
      builder.component(component_class, locals: { variant: :compact })

      expect(builder.config[:component_locals]).to eq({ variant: :compact })
    end
  end

  describe '#page_config' do
    it 'stores a page_config modifier block' do
      builder.page_config { |config| config[:title] = 'Custom' }

      expect(builder.config[:page_config_modifier]).to be_a(Proc)
    end
  end

  describe '#params_key' do
    it 'sets the params key for strong parameters' do
      builder.params_key(:user)

      expect(builder.config[:params_key]).to eq(:user)
    end
  end

  describe '#permit' do
    it 'sets permitted parameters' do
      builder.permit(:name, :email, :role)

      expect(builder.config[:permitted_params]).to eq(%i[name email role])
    end

    it 'accepts nested parameters' do
      builder.permit(:name, address: %i[street city])

      expect(builder.config[:permitted_params]).to eq([:name, { address: %i[street city] }])
    end
  end

  describe '#on_success' do
    it 'builds success handlers from block' do
      builder.on_success do
        html { redirect_to :index }
        turbo_stream { prepend :list }
      end

      expect(builder.config[:on_success]).to be_a(Hash)
      expect(builder.config[:on_success][:html]).to be_a(Proc)
      expect(builder.config[:on_success][:turbo_stream]).to be_an(Array)
    end
  end

  describe '#on_error' do
    it 'builds error handlers for specific type' do
      builder.on_error(:validation) do
        render_page status: :unprocessable_entity
      end

      expect(builder.config[:error_handlers][:validation]).to be_a(Hash)
      expect(builder.config[:error_handlers][:validation][:render_page]).to eq({ status: :unprocessable_entity })
    end

    it 'supports :any type for catch-all errors' do
      builder.on_error(:any) do
        html { redirect_to :index }
      end

      expect(builder.config[:error_handlers][:any][:html]).to be_a(Proc)
    end

    it 'supports multiple error types' do
      builder.on_error(:validation) { render_page }
      builder.on_error(:not_found) { redirect_to :index }

      expect(builder.config[:error_handlers].keys).to contain_exactly(:validation, :not_found)
    end
  end

  describe '#before' do
    it 'adds before callback' do
      builder.before { @resource = find_resource }

      expect(builder.config[:before_callbacks]).to be_an(Array)
      expect(builder.config[:before_callbacks].length).to eq(1)
    end

    it 'supports multiple before callbacks' do
      builder.before { callback_1 }
      builder.before { callback_2 }

      expect(builder.config[:before_callbacks].length).to eq(2)
    end
  end

  describe '#after' do
    it 'adds after callback' do
      builder.after { |result| log_result(result) }

      expect(builder.config[:after_callbacks]).to be_an(Array)
      expect(builder.config[:after_callbacks].length).to eq(1)
    end
  end

  describe '#skip_authentication' do
    it 'sets skip_authentication flag' do
      builder.skip_authentication

      expect(builder.config[:skip_authentication]).to be true
    end

    it 'accepts false value' do
      builder.skip_authentication(false)

      expect(builder.config[:skip_authentication]).to be false
    end
  end

  describe '#skip_authorization' do
    it 'sets skip_authorization flag' do
      builder.skip_authorization

      expect(builder.config[:skip_authorization]).to be true
    end
  end

  describe '#build' do
    it 'returns the complete configuration' do
      builder.service(ExampleService)
      builder.on_success { html { redirect_to :index } }

      config = builder.build

      expect(config[:name]).to eq(:index)
      expect(config[:service]).to eq(ExampleService)
      expect(config[:on_success]).to be_a(Hash)
    end
  end

  describe 'complete action configuration' do
    it 'supports a full action configuration' do
      builder.service(ExampleService)
      builder.params_key(:user)
      builder.permit(:name, :email)

      builder.on_success do
        html { redirect_to :index }
        turbo_stream do
          prepend :users_list
          flash type: :notice
        end
      end

      builder.on_error(:validation) do
        render_page status: :unprocessable_entity
        turbo_stream do
          replace :user_form
          form_errors
        end
      end

      config = builder.build

      expect(config[:service]).to eq(ExampleService)
      expect(config[:params_key]).to eq(:user)
      expect(config[:permitted_params]).to eq(%i[name email])
      expect(config[:on_success]).to be_present
      expect(config[:error_handlers][:validation]).to be_present
    end
  end

  describe 'turbo_stream block helpers' do
    describe 'flash helper in on_success' do
      it 'configures flash stream with type and message' do
        builder.on_success do
          turbo_stream do
            flash type: :notice, message: 'Success!'
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        flash_stream = streams.find { |s| s[:action] == :update && s[:target] == :flash }

        expect(flash_stream).to be_present
        expect(flash_stream[:locals]).to eq({ type: :notice, message: 'Success!' })
      end

      it 'uses default flash partial' do
        builder.on_success do
          turbo_stream do
            flash type: :alert
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        flash_stream = streams.find { |s| s[:target] == :flash }

        expect(flash_stream[:partial]).to eq('shared/flash')
      end
    end

    describe 'form_errors helper in on_error' do
      it 'configures form_errors stream' do
        builder.on_error(:validation) do
          turbo_stream do
            form_errors
          end
        end

        streams = builder.config[:error_handlers][:validation][:turbo_stream]
        errors_stream = streams.find { |s| s[:target] == :form_errors }

        expect(errors_stream).to be_present
        expect(errors_stream[:action]).to eq(:update)
        expect(errors_stream[:partial]).to eq('shared/form_errors')
      end

      it 'supports custom target for form_errors' do
        builder.on_error(:validation) do
          turbo_stream do
            form_errors target: :custom_errors
          end
        end

        streams = builder.config[:error_handlers][:validation][:turbo_stream]
        errors_stream = streams.find { |s| s[:target] == :custom_errors }

        expect(errors_stream).to be_present
      end
    end

    describe 'multiple stream actions in one block' do
      it 'supports all stream actions together' do
        builder.on_success do
          turbo_stream do
            append :items_list, partial: 'items/item'
            prepend :notifications
            replace :counter, partial: 'shared/counter'
            update :status
            remove :loading
            flash type: :notice
          end
        end

        streams = builder.config[:on_success][:turbo_stream]

        expect(streams.length).to eq(6)
        expect(streams.map { |s| s[:action] }).to contain_exactly(
          :append, :prepend, :replace, :update, :remove, :update
        )
      end
    end

    describe 'refresh action' do
      it 'configures refresh stream' do
        builder.on_success do
          turbo_stream do
            refresh
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        refresh_stream = streams.find { |s| s[:action] == :refresh }

        expect(refresh_stream).to be_present
      end
    end

    describe 'before and after actions' do
      it 'configures before stream action' do
        builder.on_success do
          turbo_stream do
            before :item_2, partial: 'items/item'
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        before_stream = streams.find { |s| s[:action] == :before }

        expect(before_stream[:target]).to eq(:item_2)
      end

      it 'configures after stream action' do
        builder.on_success do
          turbo_stream do
            after :item_1, partial: 'items/item'
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        after_stream = streams.find { |s| s[:action] == :after }

        expect(after_stream[:target]).to eq(:item_1)
      end
    end

    describe 'component option in streams' do
      it 'supports component option in append' do
        builder.on_success do
          turbo_stream do
            append :items_list, component: 'ItemComponent'
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        append_stream = streams.find { |s| s[:action] == :append }

        expect(append_stream[:component]).to eq('ItemComponent')
      end

      it 'supports locals with component' do
        builder.on_success do
          turbo_stream do
            replace :item, component: 'ItemComponent', locals: { item: 'test' }
          end
        end

        streams = builder.config[:on_success][:turbo_stream]
        replace_stream = streams.find { |s| s[:action] == :replace }

        expect(replace_stream[:component]).to eq('ItemComponent')
        expect(replace_stream[:locals]).to eq({ item: 'test' })
      end
    end
  end
end
