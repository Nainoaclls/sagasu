require "test_helper"

# The two AI actions are limited per user so a runaway client cannot burn OpenAI calls.
class AiRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.rate_limit_store.clear
    @buyer = create_user(name: "Aiko Buyer")
    @project = create_project(user: @buyer)
    @group = @project.item_groups.create!(title: "Masonry")
    @project.items.update_all(item_group_id: @group.id)
    sign_in_as @buyer
  end

  test "a normal AI request still works" do
    post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream

    assert_response :success
    assert_enqueued_jobs 1, only: SuggestSuppliersJob
  end

  test "supplier suggestions beyond the limit answer 429 with a toast and start nothing" do
    AiRateLimit::LIMIT.times { post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream }
    clear_enqueued_jobs

    post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream

    assert_response :too_many_requests
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=append][target=toasts] .sg-toast", /Too many AI requests/
    assert_enqueued_jobs 0
  end

  test "AI grouping beyond the limit redirects with an alert without JavaScript" do
    AiRateLimit::LIMIT.times { post generate_project_item_groups_path(@project) }

    post generate_project_item_groups_path(@project), headers: { "HTTP_REFERER" => project_url(@project) }

    assert_redirected_to project_path(@project)
    assert_equal I18n.t("flashes.application.rate_limited"), flash[:alert]
  end

  test "the limit is per user" do
    AiRateLimit::LIMIT.times { post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream }
    post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream
    assert_response :too_many_requests

    other = create_user(name: "Yuki Buyer")
    other_group = create_project(user: other).item_groups.create!(title: "Steel")
    sign_in_as other
    post suggest_item_group_group_suppliers_path(other_group), as: :turbo_stream

    assert_response :success
  end

  test "the alert is translated" do
    AiRateLimit::LIMIT.times { post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream }

    get locale_path(:fr)
    post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream

    assert_response :too_many_requests
    assert_select ".sg-toast", /Trop de demandes/
  end
end
