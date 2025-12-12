require 'spec_helper'
require 'generators/slimak/add_slug/add_slug_generator'
require 'pry'

# include Rails generator testing helpers
RSpec.describe Slimak::Generators::AddSlugGenerator, type: :generator do
  let(:dest) { File.expand_path('../tmp', __dir__) }

  before do
    FileUtils.rm_rf(dest)
    FileUtils.mkdir_p(dest)
  end

  after do
    FileUtils.rm_rf(dest)
  end

  it "creates initializer with default option" do
    generator = described_class.new(['TestApp'], {}, destination_root: dest)
    expect{generator.invoke_all}.not_to raise_error
  end

  it 'checks initializer file' do
    run_generator_with_args
    init_path = File.join(dest, 'config', 'initializers', 'slimak.rb')
    content = File.read(init_path)
    expect(content).to match(/Slimak\.configure\s+do\s+\|config\|/m)
  end

  it 'checks the migration' do
    run_generator_with_args

    migrate_dir = File.join(dest, 'db', 'migrate')
    files = Dir[File.join(migrate_dir, '*.rb')]

    expect(files).not_to be_empty
    migration_file = files.find { |f| File.basename(f) =~ /^\d{14}_.*slug.*\.rb$/ }

    migration_content = File.read(migration_file)

    expect(migration_content).to match(/class\s+\w+\s+<\s+ActiveRecord::Migration\[?\d+\.\d+\]?/)
    expect(migration_content).to match(/def\s+change/)
    expect(migration_content).to match(/add_column/)
    expect(migration_content).to match(/add_index/)
    expect(migration_content).to match(/slug/)
  end

  it 'uses provided' do
    run_generator_with_args(['TestApp'], { 'column' => 'bulbulator' })
    
    migrate_dir = File.join(dest, 'db', 'migrate')
    files = Dir[File.join(migrate_dir, '*.rb')]

    expect(files).not_to be_empty
    migration_file_with_slug_name = files.find { |f| File.basename(f) =~ /^\d{14}_.*slug.*\.rb$/ }
    expect(migration_file_with_slug_name).to be_nil

    migration_file = files.find { |f| File.basename(f) =~ /^\d{14}_.*bulbulator.*\.rb$/ }

    migration_content = File.read(migration_file)

    expect(migration_content).to match(/class\s+\w+\s+<\s+ActiveRecord::Migration\[?\d+\.\d+\]?/)
    expect(migration_content).to match(/def\s+change/)
    expect(migration_content).to match(/add_column/)
    expect(migration_content).to match(/add_index/)
    expect(migration_content).to match(/bulbulator/)
  end
end
