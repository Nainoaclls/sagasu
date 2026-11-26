require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "manifest is served as JSON with the brand colors" do
    get "/manifest.json"
    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal "Sagasu", manifest["name"]
    assert_equal "#326273", manifest["theme_color"]
    assert manifest["icons"].any? { |icon| icon["purpose"] == "maskable" }
  end

  test "service worker is served as JavaScript" do
    get "/service-worker.js"
    assert_response :success
    assert_includes response.media_type, "javascript"
    assert_includes response.body, "OFFLINE_URL"
  end

  test "offline fallback page exists" do
    get "/offline.html"
    assert_response :success
  end
end
