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
end
