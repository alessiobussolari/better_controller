# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Dsl::ResponseBuilder do
  subject(:builder) { described_class.new }

  describe '#initialize' do
    it 'initializes with an empty handlers hash' do
      expect(builder.handlers).to eq({})
    end
  end

  describe '#html' do
    it 'stores an html handler block' do
      builder.html { 'html response' }

      expect(builder.handlers[:html]).to be_a(Proc)
      expect(builder.handlers[:html].call).to eq('html response')
    end
  end

  describe '#turbo_stream' do
    it 'builds turbo stream configuration from block' do
      builder.turbo_stream do
        append :users_list
        flash type: :notice
      end

      expect(builder.handlers[:turbo_stream]).to be_an(Array)
      expect(builder.handlers[:turbo_stream].length).to eq(2)
      expect(builder.handlers[:turbo_stream].first[:action]).to eq(:append)
    end
  end

  describe '#json' do
    it 'stores a json handler block' do
      builder.json { { data: 'json' } }

      expect(builder.handlers[:json]).to be_a(Proc)
      expect(builder.handlers[:json].call).to eq({ data: 'json' })
    end
  end

  describe '#csv' do
    it 'stores a csv handler block' do
      builder.csv { 'csv response' }

      expect(builder.handlers[:csv]).to be_a(Proc)
      expect(builder.handlers[:csv].call).to eq('csv response')
    end
  end

  describe '#xml' do
    it 'stores an xml handler block' do
      builder.xml { { data: 'xml' } }

      expect(builder.handlers[:xml]).to be_a(Proc)
      expect(builder.handlers[:xml].call).to eq({ data: 'xml' })
    end
  end

  describe '#redirect_to' do
    it 'stores redirect configuration' do
      builder.redirect_to('/users', notice: 'Success!')

      expect(builder.handlers[:redirect]).to eq({
                                                  path:    '/users',
                                                  options: { notice: 'Success!' }
                                                })
    end

    it 'accepts symbol paths' do
      builder.redirect_to(:index)

      expect(builder.handlers[:redirect][:path]).to eq(:index)
    end
  end

  describe '#render_page' do
    it 'stores render_page configuration with default status' do
      builder.render_page

      expect(builder.handlers[:render_page]).to eq({ status: :ok })
    end

    it 'accepts custom status' do
      builder.render_page(status: :unprocessable_entity)

      expect(builder.handlers[:render_page][:status]).to eq(:unprocessable_entity)
    end
  end

  describe '#render_component' do
    it 'stores component render configuration' do
      builder.render_component('UserComponent', locals: { user: 'test' }, status: :created)

      expect(builder.handlers[:render_component]).to eq({
                                                          component: 'UserComponent',
                                                          locals:    { user: 'test' },
                                                          status:    :created
                                                        })
    end

    it 'uses default status of :ok' do
      builder.render_component('UserComponent')

      expect(builder.handlers[:render_component][:status]).to eq(:ok)
    end
  end

  describe '#render_partial' do
    it 'stores partial render configuration' do
      builder.render_partial('users/form', locals: { user: 'test' })

      expect(builder.handlers[:render_partial]).to eq({
                                                        partial: 'users/form',
                                                        locals:  { user: 'test' },
                                                        status:  :ok
                                                      })
    end
  end

  describe '#build' do
    it 'returns the handlers configuration' do
      builder.html { 'html' }
      builder.redirect_to('/path')

      result = builder.build

      expect(result).to eq(builder.handlers)
      expect(result.keys).to contain_exactly(:html, :redirect)
    end
  end

  describe 'complex response configuration' do
    it 'supports multiple handler types' do
      builder.html { redirect_to '/users' }
      builder.turbo_stream do
        prepend :users_list
        flash type: :notice
      end
      builder.json { { success: true } }

      expect(builder.handlers.keys).to contain_exactly(:html, :turbo_stream, :json)
    end

    it 'supports all five format handlers' do
      builder.html { 'html' }
      builder.json { { success: true } }
      builder.turbo_stream { append :list }
      builder.csv { 'csv data' }
      builder.xml { { data: 'xml' } }

      expect(builder.handlers.keys).to contain_exactly(:html, :json, :turbo_stream, :csv, :xml)
    end
  end
end
