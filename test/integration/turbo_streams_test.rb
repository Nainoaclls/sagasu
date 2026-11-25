require "test_helper"

# Actions on the project and supplier pages answer with Turbo Streams that replace only what changed.
class TurboStreamsTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @supplier = create_supplier(name: "Kanto Bricks")
    @project = create_project(user: @buyer)
    @group = @project.item_groups.create!(title: "Masonry")
    @project.items.update_all(item_group_id: @group.id)
    sign_in_as @buyer
  end

  test "selecting a supplier replaces its group card, the bidder list and the progress, with a toast" do
    link = @group.group_suppliers.create!(supplier: @supplier, ai_suggested: true, source: :ai)

    patch group_supplier_path(link), params: { group_supplier: { selected: true } }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_turbo_stream action: :replace, target: "item_group_#{@group.id}"
    assert_turbo_stream action: :replace, target: "bidder_list"
    assert_turbo_stream action: :replace, target: "project_stepper"
    assert_turbo_stream(action: :append, target: "toasts") { assert_select ".sg-toast", /added to the bidder list/ }
  end

  test "adding materials replaces the workspace sections" do
    post project_items_path(@project), params: { items: { materials_text: "Mortar; 10; bag" } }, as: :turbo_stream

    assert_turbo_stream action: :replace, target: "materials"
    assert_turbo_stream action: :replace, target: "groups"
    assert_equal 3, @project.items.count
  end

  test "starting AI suggestions shows the searching state on the card" do
    post suggest_item_group_group_suppliers_path(@group), as: :turbo_stream

    assert_turbo_stream(action: :replace, target: "item_group_#{@group.id}") { assert_select ".sg-ai-working" }
    assert_enqueued_jobs 1, only: SuggestSuppliersJob
  end

  test "renaming a group in place: the form comes in its Turbo Frame, saving re-renders the groups" do
    frame = "title_frame_item_group_#{@group.id}" # dom_id(group, :title_frame)
    get edit_item_group_path(@group), headers: { "Turbo-Frame" => frame }
    assert_response :success
    assert_select "turbo-frame##{frame} form input[name='item_group[title]']"

    patch item_group_path(@group), params: { item_group: { title: "Bricks & blocks" } }, as: :turbo_stream
    assert_turbo_stream(action: :replace, target: "groups") { assert_select "h3", "Bricks & blocks" }
  end

  test "a review appears in the list and the form resets" do
    post supplier_reviews_path(@supplier), params: { review: { rating: 5, comment: "On time", visibility: "organization" } },
                                           as: :turbo_stream

    assert_turbo_stream(action: :replace, target: "reviews") { assert_select ".sg-review", 1 }
    assert_turbo_stream action: :replace, target: "review_form"
  end

  test "an invalid review re-renders the form with errors" do
    post supplier_reviews_path(@supplier), params: { review: { rating: 5, comment: "" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_turbo_stream(action: :replace, target: "review_form", status: :unprocessable_entity) { assert_select ".alert-danger" }
  end
end
