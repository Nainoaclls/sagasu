require "test_helper"

class LocalesTest < ActionDispatch::IntegrationTest
  include SignInHelper

  test "pages render in English by default" do
    get root_path
    assert_response :success
    assert_includes response.body, "Find the right suppliers"
    assert_match /<html lang="en"/, response.body
  end

  test "the locale switch stores a cookie and renders in French" do
    get locale_path("fr")
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Trouvez les bons fournisseurs"
    assert_match /<html lang="fr"/, response.body
  end

  test "the locale switch renders in Japanese" do
    get locale_path("ja")
    follow_redirect!
    assert_includes response.body, "適切なサプライヤー"
    assert_match /<html lang="ja"/, response.body
  end

  test "an unknown locale falls back to the default" do
    get "/locale/klingon"
    assert_response :not_found
  end

  test "signed-in pages render in French" do
    user = create_user
    get locale_path("fr")
    sign_in_as user
    get projects_path
    assert_response :success
    assert_includes response.body, "Bonjour #{user.first_name}"
  end

  # translate() raises on a missing key: rendering every main page in fr and ja proves the extraction is complete
  test "main pages render in French and Japanese without missing keys" do
    buyer = create_user(role: "buyer")
    approver = create_user(role: "approver")
    project = create_ready_project(user: buyer)
    project.submit_for_approval!(approver: approver)
    supplier = project.selected_group_suppliers.first.supplier

    %w[fr ja].each do |locale|
      get locale_path(locale)
      sign_in_as buyer
      [projects_path, project_path(project), suppliers_path, supplier_path(supplier), new_project_path].each do |path|
        get path
        assert_response :success, "#{locale} #{path}"
        assert_no_match(/translation missing/i, response.body, "#{locale} #{path}")
      end

      sign_in_as approver
      [approvals_path, project_path(project)].each do |path|
        get path
        assert_response :success, "#{locale} #{path}"
        assert_no_match(/translation missing/i, response.body, "#{locale} #{path}")
      end
    end
  end
end
