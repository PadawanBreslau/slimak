require "spec_helper"

RSpec.describe "Slimak global configuration" do
  after do
    # Reset global config after each example to avoid leaking settings
    Slimak.reset!
  end

  it "uses global separator when not configured per-model" do
    Slimak.configure do |c|
      c.separator = "_"
    end

    # define a simple AR model for this spec
    class GlobalTask < ActiveRecord::Base
      self.table_name = "tasks"
      include Slimak::Sluggable
      slug_columns :name, :urgency
      # no per-model slug_options -> should use global separator
    end

    t = GlobalTask.create!(name: "Hello World", urgency: "Now")
    expect(t.slug).to include("_")
  end

  it "uses global conflict strategy if model doesn't override" do
    Slimak.configure do |c|
      c.conflict_strategy = :random
      c.random_suffix_length = 3
    end

    class GlobalTask2 < ActiveRecord::Base
      self.table_name = "tasks"
      include Slimak::Sluggable
      slug_columns :name, :urgency
    end

    a = GlobalTask2.create!(name: "Do it", urgency: "Now", assignee_name: "Sam")
    b = GlobalTask2.create!(name: "Do it", urgency: "Now", assignee_name: "Sam")
    expect(a.slug).not_to eq(b.slug)
    expect(b.slug.length).to be > a.slug.length
  end

  it "merges global slug_column_limits with per-model limits (model wins)" do
    Slimak.configure do |c|
      c.slug_column_limits = { name: 10, urgency: 5 }
    end

    class GlobalTask3 < ActiveRecord::Base
      self.table_name = "tasks"
      include Slimak::Sluggable
      slug_columns :name, :urgency
      slug_column_limits name: 4 # per-model override
    end

    t = GlobalTask3.create!(name: "Painting", urgency: "Attention")
    # name should be truncated to 4 chars
    expect(t.slug).to include("pain") # "Pain" lowercased -> "pain"
    # urgency should still be limited by global limit (5 chars -> e.g., "Atten")
    expect(t.slug).to match(/atten|atten/i)
  end
end
