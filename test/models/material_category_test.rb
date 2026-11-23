require "test_helper"

class MaterialCategoryTest < ActiveSupport::TestCase
  test "classifies common construction materials" do
    assert_equal "masonry", MaterialCategory.classify("Facing bricks, red")
    assert_equal "steel", MaterialCategory.classify("Rebar D13 SD345")
    assert_equal "insulation", MaterialCategory.classify("Glass wool 100mm")
    assert_equal "plumbing", MaterialCategory.classify("PVC drain pipe")
  end

  test "falls back to other" do
    assert_equal MaterialCategory::OTHER, MaterialCategory.classify("Something unusual")
    assert_equal "Other materials", MaterialCategory.label(MaterialCategory::OTHER)
  end
end
