require "test_helper"

class SupplierMapTest < ActionDispatch::IntegrationTest
  test "suppliers index renders the map when a Mapbox token is set" do
    create_supplier(latitude: 35.6667, longitude: 139.8167)
    sign_in_as create_user
    with_mapbox_token { get suppliers_path }
    assert_response :success
    assert_select "[data-controller='map'][data-map-token-value='test-token']"
  end

  test "suppliers index has no map without a token" do
    create_supplier(latitude: 35.6667, longitude: 139.8167)
    sign_in_as create_user
    # .env may define a real token (dotenv loads it in test too): remove it for this case
    with_mapbox_token(nil) { get suppliers_path }
    assert_response :success
    assert_select "[data-controller='map']", false
  end

  test "supplier profile renders the focused map when geocoded" do
    supplier = create_supplier(latitude: 35.6667, longitude: 139.8167)
    sign_in_as create_user
    with_mapbox_token { get supplier_path(supplier) }
    assert_response :success
    assert_select "[data-controller='map']"
  end

  test "supplier profile has no map when the supplier has no coordinates" do
    supplier = create_supplier(city: "Ome", prefecture: "Tokyo")
    sign_in_as create_user
    with_mapbox_token { get supplier_path(supplier) }
    assert_response :success
    assert_select "[data-controller='map']", false
  end

  private

  # Runs the block with a given token (nil = no token), then restores the original value
  def with_mapbox_token(token = "test-token")
    previous = ENV["MAPBOX_ACCESS_TOKEN"]
    ENV["MAPBOX_ACCESS_TOKEN"] = token
    yield
  ensure
    ENV["MAPBOX_ACCESS_TOKEN"] = previous
  end
end
