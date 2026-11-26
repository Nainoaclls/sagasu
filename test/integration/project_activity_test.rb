require "test_helper"

# The activity page lists what happened on a project (AI runs, submission, decision) for the people
# who can see the project, and nobody else.
class ProjectActivityTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_ready_project(user: @buyer)
    @group = @project.item_groups.first
    @project.ai_runs.create!(user: @buyer, kind: :grouping, status: :fallback, prompt: "SECRET PROMPT")
    @project.ai_runs.create!(user: @buyer, kind: :supplier_suggestion, item_group: @group, status: :succeeded,
                             model: "gpt-4.1", output: "SECRET OUTPUT")
    @project.submit_for_approval!(approver: @approver, comment: "Please check the bricks")
    @project.pending_approval_record.decide!(decision: :returned, comment: "Add a second mason")
  end

  test "the owner sees every kind of event, newest first, without prompts or outputs" do
    sign_in_as @buyer

    get project_activity_path(@project)

    assert_response :success
    assert_select ".sg-activity-item", 5
    assert_select ".sg-activity-item", text: /Aiko Buyer created the project/
    assert_select ".sg-activity-item", text: /AI grouping.*Offline matching/m
    assert_select ".sg-activity-item", text: /suggestions for “Masonry”.*Done by AI/m
    assert_select ".sg-activity-item", text: /sent the bidder list to Kenji Approver.*Please check the bricks/m
    assert_select ".sg-activity-item", text: /Kenji Approver returned.*Add a second mason/m
    assert_no_match(/SECRET/, response.body)
    assert_operator response.body.index("returned the bidder list"), :<, response.body.index("created the project")
  end

  test "the assigned approver can see it" do
    sign_in_as @approver

    get project_activity_path(@project)

    assert_response :success
  end

  test "another user is redirected" do
    sign_in_as create_user(name: "Stranger")

    get project_activity_path(@project)

    assert_redirected_to projects_path
  end

  test "the page renders in French and Japanese" do
    sign_in_as @buyer

    get locale_path("fr")
    get project_activity_path(@project)
    assert_select "h1", "Activité du projet"
    assert_select ".sg-activity-item", text: /a créé le projet/

    get locale_path("ja")
    get project_activity_path(@project)
    assert_select "h1", "プロジェクトのアクティビティ"
    assert_select ".sg-activity-item", text: /プロジェクトを作成しました/
  end

  test "the project page links to the activity" do
    sign_in_as @buyer

    get project_path(@project)

    assert_select "a[href=?]", project_activity_path(@project)
  end
end
