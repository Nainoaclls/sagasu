require "test_helper"

class RfqInvitationBuilderTest < ActiveSupport::TestCase
  setup do
    @buyer = create_user(role: "buyer")
    @project = create_ready_project(user: @buyer)
    # A second group with its own supplier: it must never leak into the invitation.
    @other_group = @project.item_groups.create!(title: "Steel frames")
    @other_supplier = create_supplier(name: "Kanto Steel")
    @other_group.group_suppliers.create!(supplier: @other_supplier, selected: true)
    @project.submit_for_approval!(approver: create_user(role: "approver"))
    @approval = @project.latest_approval
    @supplier = @project.selected_group_suppliers.first.supplier
  end

  test "body contains the snapshot quantities, not the current ones" do
    item = @project.items.first
    frozen_quantity = item.quantity
    item.update!(quantity: item.quantity + 999) # editing after approval must not leak

    builder = RfqInvitationBuilder.new(approval: @approval, supplier: @supplier)
    assert_includes builder.body, frozen_quantity.to_s
    assert_not_includes builder.body, (frozen_quantity + 999).to_s
  end

  test "only the supplier's own groups appear" do
    builder = RfqInvitationBuilder.new(approval: @approval, supplier: @supplier)
    assert_equal 1, builder.groups.size
    assert_not_equal @other_group.title, builder.groups.first["title"]
    assert_not_includes builder.body, @other_supplier.name
  end

  test "a supplier on no snapshot group gets no body" do
    stranger = create_supplier(name: "Nowhere Supplies")
    assert_raises(RfqInvitationBuilder::MissingMaterialList) do
      RfqInvitationBuilder.new(approval: @approval, supplier: stranger).body
    end
  end

  test "renders subject and body in every locale" do
    builder = RfqInvitationBuilder.new(approval: @approval, supplier: @supplier)
    %i[en fr ja].each do |locale|
      I18n.with_locale(locale) do
        assert builder.subject.present?
        assert_includes builder.body, @supplier.name
        assert_includes builder.body, builder.material_list
      end
    end
  end

  test "falls back to a translated reference when the project has no ERP RFQ" do
    assert_nil @project.erp_rfq
    builder = RfqInvitationBuilder.new(approval: @approval, supplier: @supplier)
    I18n.with_locale(:fr) { assert_equal "Appel d'offres", builder.rfq_reference }
  end
end
