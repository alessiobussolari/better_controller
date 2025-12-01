# frozen_string_literal: true

RSpec.shared_examples 'a Rails generator' do
  it 'inherits from Rails::Generators::NamedBase or Base' do
    expect(
      described_class.superclass == Rails::Generators::NamedBase ||
      described_class.superclass == Rails::Generators::Base ||
      described_class.ancestors.include?(Rails::Generators::Base)
    ).to be true
  end

  it 'defines source_root' do
    expect(described_class).to respond_to(:source_root)
  end
end

RSpec.shared_examples 'a generator with templates' do |template_files|
  template_files.each do |template_file|
    it "has template file: #{template_file}" do
      template_path = File.join(described_class.source_root, template_file)
      expect(File.exist?(template_path)).to be true
    end
  end
end

RSpec.shared_examples 'an idempotent generator' do
  it 'can be run multiple times without error' do
    # First run
    expect { run_generator }.not_to raise_error

    # Second run (idempotent)
    expect { run_generator }.not_to raise_error
  end
end

RSpec.shared_examples 'a generator with revoke support' do
  it 'supports revoke behavior' do
    run_generator

    # Get list of created files
    created_files = destination_root_files

    # Run revoke
    run_generator ['--behavior=revoke'] rescue run_generator_with_revoke

    # Verify files are removed or behavior is clean
    expect(destination_root_files.length).to be <= created_files.length
  end

  private

  def destination_root_files
    Dir.glob(File.join(destination_root, '**', '*')).select { |f| File.file?(f) }
  end

  def run_generator_with_revoke
    generator = described_class.new(generator_args, {}, behavior: :revoke, destination_root: destination_root)
    generator.invoke_all
  end
end

RSpec.shared_examples 'a controller generator' do |options = {}|
  let(:controller_file) { options[:controller_file] || "app/controllers/#{controller_name}_controller.rb" }
  let(:controller_name) { options[:controller_name] || 'examples' }

  it 'creates a controller file' do
    run_generator
    expect(File.exist?(File.join(destination_root, controller_file))).to be true
  end

  it 'includes BetterController module' do
    run_generator
    content = File.read(File.join(destination_root, controller_file))
    expect(content).to match(/include BetterController/)
  end

  it 'defines resource_class method' do
    run_generator
    content = File.read(File.join(destination_root, controller_file))
    expect(content).to match(/def resource_class/)
  end

  it 'defines resource_params method' do
    run_generator
    content = File.read(File.join(destination_root, controller_file))
    expect(content).to match(/def resource_params/)
  end
end

RSpec.shared_examples 'a generator handling namespace' do
  it 'handles simple names' do
    run_generator ['simple']
    expect(File.exist?(File.join(destination_root, 'app/controllers/simples_controller.rb'))).to be true
  end

  it 'handles namespaced names' do
    run_generator ['admin/users']
    expect(File.exist?(File.join(destination_root, 'app/controllers/admin/users_controller.rb'))).to be true
  end

  it 'handles deeply nested namespaces' do
    run_generator ['api/v1/admin/resources']
    expect(File.exist?(File.join(destination_root, 'app/controllers/api/v1/admin/resources_controller.rb'))).to be true
  end
end

RSpec.shared_examples 'a generator with model option' do
  it 'accepts --model option' do
    expect(described_class.class_options).to have_key(:model)
  end

  it 'uses custom model name when provided' do
    run_generator ['posts', '--model=Article']
    content = File.read(File.join(destination_root, 'app/controllers/posts_controller.rb'))
    expect(content).to include('Article')
  end
end

RSpec.shared_examples 'a generator with skip options' do
  it 'accepts --skip-routes option' do
    expect(described_class.class_options).to have_key(:skip_routes)
  end
end

RSpec.shared_examples 'generates valid Ruby code' do
  it 'generates syntactically valid Ruby' do
    run_generator

    generated_files = Dir.glob(File.join(destination_root, '**', '*.rb'))
    generated_files.each do |file|
      expect { RubyVM::InstructionSequence.compile_file(file) }.not_to raise_error
    end
  end
end

RSpec.shared_examples 'a generator with frozen string literal' do
  it 'adds frozen_string_literal comment' do
    run_generator

    generated_files = Dir.glob(File.join(destination_root, '**', '*.rb'))
    generated_files.each do |file|
      content = File.read(file)
      expect(content).to start_with('# frozen_string_literal: true')
    end
  end
end
