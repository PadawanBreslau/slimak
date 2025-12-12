require 'spec_helper'
require 'generators/slimak/add_jsonb_slug/add_jsonb_slug_generator'

# include Rails generator testing helpers
RSpec.describe Slimak::Generators::AddJsonbSlugGenerator, type: :generator do
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
    expect(migration_content).to match(/jsonb/)
    expect(migration_content).to match(/default/)
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
    expect(migration_content).to match(/jsonb/)
    expect(migration_content).to match(/default/)
    expect(migration_content).to match(/add_index/)
    expect(migration_content).to match(/bulbulator/)
  end

    it 'does not overwrite existing initializer when no force option is provided' do
    init_dir = File.join(dest, 'config', 'initializers')
    FileUtils.mkdir_p(init_dir)
    existing_content = "# existing initializer\n"
    init_path = File.join(init_dir, 'slimak.rb')
    File.write(init_path, existing_content)

    # run generator WITHOUT force
    run_generator_with_args(['TestApp'], {})

    expect(File).to exist(init_path)
    expect(File.read(init_path)).to eq(existing_content)
  end

  it 'overwrites existing initializer when force option is provided' do
    init_dir = File.join(dest, 'config', 'initializers')
    FileUtils.mkdir_p(init_dir)
    existing_content = "# existing initializer\n"
    init_path = File.join(init_dir, 'slimak.rb')
    File.write(init_path, existing_content)

    # run generator WITH force
    run_generator_with_args(['TestApp'], { 'force' => true })

    expect(File).to exist(init_path)
    new_content = File.read(init_path)
    expect(new_content).to match(/Slimak\.configure/)
    expect(new_content).not_to eq(existing_content)
  end
end
