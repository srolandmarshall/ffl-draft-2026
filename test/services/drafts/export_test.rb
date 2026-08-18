require "test_helper"

module Drafts
  class ExportTest < ActiveSupport::TestCase
    test "produces a commissioner-friendly roster CSV" do
      draft = drafts(:one)
      MakePick.new(draft:, team: teams(:one), player: players(:one)).call

      csv = CSV.parse(Export.new(draft.reload).to_csv, headers: true)

      assert_equal Export::HEADERS, csv.headers
      assert_equal "Red Hawks", csv.first["team"]
      assert_equal "Alex Archer", csv.first["player"]
      assert_equal "1", csv.first["espn_id"]
    end
  end
end
