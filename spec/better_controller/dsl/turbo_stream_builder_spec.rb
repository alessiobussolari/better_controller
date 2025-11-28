# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Dsl::TurboStreamBuilder do
  subject(:builder) { described_class.new }

  describe '#initialize' do
    it 'initializes with an empty streams array' do
      expect(builder.streams).to eq([])
    end
  end

  describe '#append' do
    it 'adds an append stream configuration' do
      builder.append(:users_list, partial: 'users/user', locals: { user: 'test' })

      expect(builder.streams.length).to eq(1)
      expect(builder.streams.first).to eq({
                                            action:    :append,
                                            target:    :users_list,
                                            component: nil,
                                            partial:   'users/user',
                                            locals:    { user: 'test' }
                                          })
    end

    it 'accepts a component option' do
      builder.append(:users_list, component: 'UserComponent')

      expect(builder.streams.first[:component]).to eq('UserComponent')
    end
  end

  describe '#prepend' do
    it 'adds a prepend stream configuration' do
      builder.prepend(:notifications)

      expect(builder.streams.first[:action]).to eq(:prepend)
      expect(builder.streams.first[:target]).to eq(:notifications)
    end
  end

  describe '#replace' do
    it 'adds a replace stream configuration' do
      builder.replace(:user_1, partial: 'users/user')

      expect(builder.streams.first[:action]).to eq(:replace)
      expect(builder.streams.first[:target]).to eq(:user_1)
    end
  end

  describe '#update' do
    it 'adds an update stream configuration' do
      builder.update(:counter, partial: 'shared/counter')

      expect(builder.streams.first[:action]).to eq(:update)
      expect(builder.streams.first[:target]).to eq(:counter)
    end
  end

  describe '#remove' do
    it 'adds a remove stream configuration' do
      builder.remove(:notification_1)

      expect(builder.streams.first).to eq({
                                            action: :remove,
                                            target: :notification_1
                                          })
    end
  end

  describe '#before' do
    it 'adds a before stream configuration' do
      builder.before(:user_2, partial: 'users/user')

      expect(builder.streams.first[:action]).to eq(:before)
    end
  end

  describe '#after' do
    it 'adds an after stream configuration' do
      builder.after(:user_1, partial: 'users/user')

      expect(builder.streams.first[:action]).to eq(:after)
    end
  end

  describe '#flash' do
    it 'adds a flash update stream' do
      builder.flash(type: :notice, message: 'Success!')

      expect(builder.streams.first).to eq({
                                            action:  :update,
                                            target:  :flash,
                                            partial: 'shared/flash',
                                            locals:  { type: :notice, message: 'Success!' }
                                          })
    end

    it 'uses default flash type of :notice' do
      builder.flash

      expect(builder.streams.first[:locals][:type]).to eq(:notice)
    end
  end

  describe '#form_errors' do
    it 'adds a form errors update stream' do
      errors = { name: ["can't be blank"] }
      builder.form_errors(errors: errors)

      expect(builder.streams.first).to eq({
                                            action:  :update,
                                            target:  :form_errors,
                                            partial: 'shared/form_errors',
                                            locals:  { errors: errors }
                                          })
    end

    it 'allows custom target' do
      builder.form_errors(errors: nil, target: :custom_errors)

      expect(builder.streams.first[:target]).to eq(:custom_errors)
    end
  end

  describe '#refresh' do
    it 'adds a refresh stream' do
      builder.refresh

      expect(builder.streams.first).to eq({ action: :refresh })
    end
  end

  describe '#build' do
    it 'returns all configured streams' do
      builder.append(:list)
      builder.remove(:item)
      builder.flash

      result = builder.build

      expect(result.length).to eq(3)
      expect(result.map { |s| s[:action] }).to eq(%i[append remove update])
    end
  end

  describe 'chaining multiple streams' do
    it 'supports method chaining for multiple streams' do
      builder.replace(:user_1, partial: 'users/user')
      builder.update(:counter, partial: 'shared/counter')
      builder.flash(type: :notice)

      expect(builder.streams.length).to eq(3)
    end
  end
end
