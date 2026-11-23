require "test_helper"

class MaterialListParserTest < ActiveSupport::TestCase
  def parse(text)
    MaterialListParser.parse(text)
  end

  test "semicolon and pipe columns" do
    rows = parse("Red clay bricks; 50000; pcs\nMortar | 1,200 | bag")
    assert_equal ["Red clay bricks", 50_000, "pcs"], rows.first.values_at(:description, :quantity, :unit_of_measure)
    assert_equal 1200, rows.last[:quantity]
  end

  test "Excel paste with an ERP code first" do
    row = parse("MAT-0042\tPortland cement\t400\tbag").first
    assert_equal "MAT-0042", row[:erp_material]
    assert_equal "Portland cement", row[:description]
  end

  test "free text with quantity before or after" do
    assert_equal({ description: "facing bricks", quantity: 50_000, unit_of_measure: "pcs" }, parse("50,000 pcs facing bricks").first)
    assert_equal 40, parse("Rebar D13 x 40 t").first[:quantity]
    assert_equal 2000, parse("Sand 2k t").first[:quantity]
  end

  test "a size spec is not read as a quantity" do
    assert_equal({ description: "PVC pipe 100mm" }, parse("PVC pipe 100mm").first)
  end

  test "ignores blank lines and caps the list" do
    assert_equal 2, parse("\nBricks\n\n  \nMortar\n").size
    assert_equal MaterialListParser::MAX_LINES, parse(Array.new(250) { |i| "Item #{i}" }.join("\n")).size
  end
end
