require "spec_helper"

RSpec.describe "Slimak ActiveRecord integration" do
  it "generates a slug from multiple columns and persists it" do
    t = Task.create!(name: "Paint the wall", urgency: "Critical", assignee_name: "Mark")
    expect(t._slug).to eq("paint-the-wall-critical-mark")
    expect(Task.find_by_slug("paint-the-wall-critical-mark")).to eq(t)
  end

  it "does not override an explicitly provided slug" do
    t = Task.create!(name: "Whatever", urgency: "Low", assignee_name: "Sue", slug: "explicit")
    expect(t._slug).to eq("explicit")
  end

  it "appends sequence numbers on conflicts by default" do
    a = Task.create!(name: "Paint the wall", urgency: "Critical", assignee_name: "Mark")
    b = Task.create!(name: "Paint the wall", urgency: "Critical", assignee_name: "Mark")
    c = Task.create!(name: "Paint the wall", urgency: "Critical", assignee_name: "Mark")
    expect(a._slug).to eq("paint-the-wall-critical-mark")
    expect(b._slug).to match(/\Apaint-the-wall-critical-mark(-2)?\z/)
    expect(c._slug).to match(/\Apaint-the-wall-critical-mark(-3)?\z/)
    expect([a._slug, b.slug, c.slug].uniq.length).to eq(3)
  end

  it "supports random suffix conflict strategy" do
    Task.slug_options conflict_strategy: :random, random_suffix_length: 4, sequence_separator: "-"
    a = Task.create!(name: "Do it", urgency: "Now", assignee_name: "Sam")
    b = Task.create!(name: "Do it", urgency: "Now", assignee_name: "Sam")
    expect(a._slug).to match(/\Ado-it-now-sam\z|do-it-now-sam-/i)
    expect(b._slug).not_to eq(a.slug)
    expect(b._slug).to match(/\Ado-it-now-sam(-|[a-z0-9])+/i)
    # reset options
    Task.slug_options Task.default_slug_options
  end

  it "respects per-column limits" do
    Task.slug_column_limits name: 4, assignee_name: 2
    t = Task.create!(name: "Painting", urgency: "High", assignee_name: "Martin")
    # name truncated to first 4 chars -> "Pain", assignee_name -> "Ma"
    expect(t._slug).to include("pain")
    expect(t._slug).to include("ma")
    Task.slug_column_limits({})
  end

  it "supports scoped uniqueness" do
    Task.slug_options scope: :project_id
    Task.slug_column_limits assignee_name: 5, name: 8
    t1 = Task.create!(name: "Fix bug", urgency: "High", assignee_name: "Alice", project_id: 1)
    t2 = Task.create!(name: "Fix bug", urgency: "High", assignee_name: "Alice", project_id: 1)
    t3 = Task.create!(name: "Fix bug", urgency: "High", assignee_name: "Alice", project_id: 2)
    expect(t1._slug).to eq("fix-bug-high-alice")
    expect(t2._slug).to match(/\Afix-bug-high-alice(-2)?\z/)
    expect(t3._slug).to eq("fix-bug-high-alice")
    Task.slug_options Task.default_slug_options
  end

  it "find_by_slug! raises when not found" do
    expect { Task.find_by_slug!("not-here") }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
