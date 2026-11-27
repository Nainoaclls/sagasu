require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "geocodes the address when it has no coordinates" do
    Geocoder::Lookup::Test.add_stub("Koto, Tokyo, Japan", [ { "coordinates" => [ 35.6667, 139.8167 ] } ])
    supplier = create_supplier(name: "Map Test", city: "Koto", prefecture: "Tokyo")
    assert_in_delta 35.6667, supplier.latitude, 0.0001
    assert_in_delta 139.8167, supplier.longitude, 0.0001
  end

  test "trusts coordinates given at creation (seeds, imports)" do
    Geocoder::Lookup::Test.add_stub("Koto, Tokyo, Japan", [ { "coordinates" => [ 1.0, 1.0 ] } ])
    supplier = create_supplier(city: "Koto", prefecture: "Tokyo", latitude: 35.5, longitude: 139.5)
    assert_in_delta 35.5, supplier.latitude, 0.0001
  end

  test "re-geocodes when the address changes" do
    Geocoder::Lookup::Test.add_stub("Mito, Ibaraki, Japan", [ { "coordinates" => [ 36.3659, 140.4713 ] } ])
    supplier = create_supplier(latitude: 35.5, longitude: 139.5)
    supplier.update!(city: "Mito", prefecture: "Ibaraki")
    assert_in_delta 36.3659, supplier.latitude, 0.0001
  end

  test "with_coordinates keeps only geocoded suppliers" do
    geocoded = create_supplier(latitude: 35.5, longitude: 139.5)
    create_supplier(city: "Ome", prefecture: "Tokyo") # never stubbed: stays without coordinates
    assert_equal [ geocoded ], Supplier.with_coordinates.to_a
  end

  test "accepts a single valid contact email, or none" do
    assert create_supplier(email: "sales@akabane.example").persisted?
    assert create_supplier(email: "").persisted?
    assert create_supplier(email: nil).persisted?
  end

  test "rejects contact emails that could break a mailto link" do
    [
      "not-an-email",
      "sales@akabane.example, other@akabane.example",   # address list
      "sales@akabane.example;other@akabane.example",    # separator
      "sales@akabane.example?subject=x",                # query in the address itself
      "sales@akabane.example&cc=x@y.example",
      "sales@akabane.example#frag",
      "sales@akabane.example\nBcc: spy@evil.example"    # header injection
    ].each do |email|
      assert_not create_supplier(email: "ok@ok.example").tap { |s| s.email = email }.valid?, "expected #{email.inspect} to be invalid"
    end
  end
end
