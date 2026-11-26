require "test_helper"

# A buyer can correct, duplicate and delete projects, within the rules of the approval workflow.
class ProjectManagementTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_ready_project(user: @buyer)
    sign_in_as @buyer
  end

  test "the owner edits the details of a draft" do
    get edit_project_path(@project)
    assert_response :success

    patch project_path(@project), params: { project: { title: "New title", budget_amount: 5000, materials_text: "Ignored; 1; pcs" } }

    assert_redirected_to project_path(@project)
    assert_equal "New title", @project.reload.title
    assert_equal 2, @project.items.count
  end

  test "an invalid title re-renders the form" do
    patch project_path(@project), params: { project: { title: "" } }

    assert_response :unprocessable_entity
    assert_equal "Test project", @project.reload.title
  end

  test "a project waiting for approval cannot be edited or deleted" do
    @project.submit_for_approval!(approver: @approver)

    get edit_project_path(@project)
    assert_redirected_to projects_path
    patch project_path(@project), params: { project: { title: "Sneaky" } }
    assert_equal "Test project", @project.reload.title
    delete project_path(@project)
    assert Project.exists?(@project.id)
  end

  test "the owner deletes an untouched draft" do
    assert_difference -> { Project.count }, -1 do
      delete project_path(@project)
    end

    assert_redirected_to projects_path
    assert_equal 0, Item.where(project_id: @project.id).count
  end

  test "a returned project keeps its history and cannot be deleted" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.decide!(decision: :returned, comment: "Redo")

    delete project_path(@project)

    assert Project.exists?(@project.id)
    get edit_project_path(@project)
    assert_response :success
  end

  test "duplicating copies details, materials and groups but no suppliers or approvals" do
    @project.update!(scope: "Office tower", client_name: "Shinjuku Corp", erp_rfq: "RFQ-1")
    @project.submit_for_approval!(approver: @approver)

    assert_difference -> { @buyer.projects.count }, 1 do
      post duplicate_project_path(@project)
    end

    copy = @buyer.projects.order(:id).last
    assert_redirected_to project_path(copy)
    assert_equal "Test project (copy)", copy.title
    assert_equal "Office tower", copy.scope
    assert_nil copy.erp_rfq
    assert copy.draft?
    assert_equal @project.items.pluck(:description), copy.items.pluck(:description)
    assert_equal ["Masonry"], copy.item_groups.pluck(:title)
    assert_equal copy.item_groups.first.id, copy.items.first.item_group_id
    assert_equal 0, copy.group_suppliers.count
    assert_equal 0, copy.approvals.count
  end

  test "an approver cannot edit or duplicate a project they review" do
    @project.submit_for_approval!(approver: @approver)
    sign_in_as @approver

    post duplicate_project_path(@project)
    assert_redirected_to projects_path
    get edit_project_path(@project)
    assert_redirected_to projects_path
    assert_equal 0, @approver.projects.count
  end

  test "the project page shows the actions only when they are allowed" do
    get project_path(@project)
    assert_select "a[href=?]", edit_project_path(@project)
    assert_select "form[action=?]", duplicate_project_path(@project)
    assert_select "form[action=?][method=post] input[name=_method][value=delete]", project_path(@project)

    @project.submit_for_approval!(approver: @approver)
    get project_path(@project)
    assert_select "a[href=?]", edit_project_path(@project), 0
    assert_select "form[action=?]", duplicate_project_path(@project)
    assert_select "form[action=?] input[name=_method][value=delete]", project_path(@project), 0
  end

  test "the edit page renders in French and Japanese" do
    get locale_path("fr")
    get edit_project_path(@project)
    assert_select "h1", "Modifier le projet"

    get locale_path("ja")
    get edit_project_path(@project)
    assert_select "h1", "プロジェクトを編集"
  end
end
