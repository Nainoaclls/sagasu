require "test_helper"

# Buyers keep the supplier records; approvers only read them.
class SupplierManagementTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
  end

  test "a buyer adds a supplier" do
    sign_in_as @buyer
    get new_supplier_path
    assert_response :success

    assert_difference -> { Supplier.count }, 1 do
      post suppliers_path, params: { supplier: {
        name: "Chiba Cement", category: "concrete", prefecture: "Chiba", city: "Ichihara",
        delivery_areas: ["", "Chiba", "Tokyo"], monthly_capacity: 800, capacity_unit: "t", lead_time_days: 5,
        certifications_text: "JIS R 5210, ISO 9001 ,, JIS R 5210", website: "https://chiba-cement.example",
        erp_vendor_code: " V-100 "
      } }
    end

    supplier = Supplier.find_by!(name: "Chiba Cement")
    assert_redirected_to supplier_path(supplier)
    assert_equal %w[Chiba Tokyo], supplier.delivery_areas
    assert_equal ["JIS R 5210", "ISO 9001"], supplier.certifications
    assert_equal "V-100", supplier.erp_vendor_code
  end

  test "invalid data re-renders the form" do
    sign_in_as @buyer

    assert_no_difference -> { Supplier.count } do
      post suppliers_path, params: { supplier: { name: "", category: "concrete", website: "javascript:alert(1)",
                                                 delivery_areas: ["Atlantis"], prefecture: "Atlantis" } }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback, .error"
  end

  test "blank vendor codes do not collide but a real duplicate is refused" do
    create_supplier(erp_vendor_code: "V-1")
    sign_in_as @buyer

    2.times { |n| post suppliers_path, params: { supplier: { name: "No code #{n}", category: "masonry", erp_vendor_code: "" } } }
    assert_equal 2, Supplier.where(name: ["No code 0", "No code 1"], erp_vendor_code: nil).count

    post suppliers_path, params: { supplier: { name: "Copycat", category: "masonry", erp_vendor_code: "V-1" } }
    assert_response :unprocessable_entity
    assert_nil Supplier.find_by(name: "Copycat")
  end

  test "a buyer edits a supplier" do
    supplier = create_supplier(name: "Old name")
    sign_in_as @buyer

    get edit_supplier_path(supplier)
    assert_response :success
    patch supplier_path(supplier), params: { supplier: { name: "New name", certifications_text: "" } }

    assert_redirected_to supplier_path(supplier)
    assert_equal "New name", supplier.reload.name
    assert_equal [], supplier.certifications
  end

  test "an approver cannot create or edit suppliers" do
    supplier = create_supplier
    sign_in_as @approver

    get new_supplier_path
    assert_redirected_to projects_path
    post suppliers_path, params: { supplier: { name: "Nope", category: "masonry" } }
    assert_nil Supplier.find_by(name: "Nope")
    patch supplier_path(supplier), params: { supplier: { name: "Hacked" } }
    assert_not_equal "Hacked", supplier.reload.name
  end

  test "the add and edit links are shown to buyers only" do
    supplier = create_supplier
    sign_in_as @buyer
    get suppliers_path
    assert_select "a[href=?]", new_supplier_path
    get supplier_path(supplier)
    assert_select "a[href=?]", edit_supplier_path(supplier)

    sign_in_as @approver
    get suppliers_path
    assert_select "a[href=?]", new_supplier_path, 0
    get supplier_path(supplier)
    assert_select "a[href=?]", edit_supplier_path(supplier), 0
  end

  test "the form renders in French and Japanese" do
    sign_in_as @buyer

    get locale_path("fr")
    get new_supplier_path
    assert_select "h1", "Ajouter un fournisseur"

    get locale_path("ja")
    get new_supplier_path
    assert_select "h1", "サプライヤーを追加"
  end
end
