require "spec_helper"

RSpec.describe "Slimak ActiveRecord integration with JSON" do
  xit "generates a slug from multiple columns and persists it" do
    t = TranslatedTask.create!(name: "Paint the wall", urgency: "Critical", assignee_name: "Mark")
    expect(t._slug).to eq("paint-the-wall-critical-mark")
    expect(Task.find_by_slug("paint-the-wall-critical-mark")).to eq(t)
  end
end
