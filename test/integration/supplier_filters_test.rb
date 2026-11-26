require "test_helper"

# The supplier search can also be narrowed by certification and lead time.
class SupplierFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @certified = create_supplier(name: "Zeta Certified", certifications: ["ISO 9001"], lead_time_days: 5)
    @slow = create_supplier(name: "Zeta Slow", certifications: ["JIS A 5210"], lead_time_days: 20)
    @unknown = create_supplier(name: "Zeta Unknown", certifications: [], lead_time_days: nil)
    sign_in_as create_user
  end

  test "filtering by certification keeps only suppliers holding it" do
    names = Supplier.filter_by(query: "Zeta", category: nil, area: nil, certification: "ISO 9001").pluck(:name)

    assert_equal ["Zeta Certified"], names
  end

  test "filtering by lead time excludes slower and unknown suppliers" do
    names = Supplier.filter_by(query: "Zeta", category: nil, area: nil, max_lead_time: "7").pluck(:name)

    assert_equal ["Zeta Certified"], names
    assert_equal 2, Supplier.filter_by(query: "Zeta", category: nil, area: nil, max_lead_time: "30").count
  end

  test "blank filters change nothing" do
    assert_equal 3, Supplier.filter_by(query: "Zeta", category: nil, area: nil, certification: "", max_lead_time: "").count
  end

  test "the search page applies the filters and offers every recorded certification" do
    get suppliers_path, params: { query: "Zeta", certification: "ISO 9001", max_lead_time: 7 }

    assert_response :success
    assert_select ".sg-supplier-card", 1
    assert_select ".sg-supplier-card", text: /Zeta Certified/
    assert_select "select[name=certification] option", text: "JIS A 5210"
    assert_select "select[name=max_lead_time] option[selected]", text: /7/
  end

  test "the filters render in French and Japanese" do
    get locale_path("fr")
    get suppliers_path
    assert_select "select[name=max_lead_time] option", text: "Sous 7 jours"

    get locale_path("ja")
    get suppliers_path
    assert_select "select[name=max_lead_time] option", text: "7日以内"
  end
end
