require "test_helper"

class ApprovalDocumentTest < ActiveSupport::TestCase
  setup do
    @buyer = create_user
    @project = create_ready_project(user: @buyer)
    link = @project.group_suppliers.first
    link.update!(evidence: ["Delivered 3 similar towers", "JIS certified"],
                 missing_info: ["Monthly capacity to confirm"])
    @approval = @project.submit_for_approval!(approver: create_user(role: "approver"))
  end

  test "renders a PDF in every UI locale" do
    %w[en fr ja].each do |locale|
      bytes = ApprovalDocument.new(@approval, locale: locale).render
      assert bytes.start_with?("%PDF"), "#{locale} should render a PDF"
      assert bytes.bytesize > 1_000, "#{locale} PDF should not be empty"
    end
  end

  test "still renders for snapshots frozen before evidence was stored" do
    legacy = @approval.snapshot
    legacy["groups"].each do |group|
      group["suppliers"].each { |supplier| supplier.except!("evidence", "missing_info") }
    end
    @approval.update!(snapshot: legacy)

    assert ApprovalDocument.new(@approval, locale: :en).render.start_with?("%PDF")
  end

  test "the filename carries the approval id and the locale" do
    assert_equal "sagasu-approval-#{@approval.id}-ja.pdf", ApprovalDocument.new(@approval, locale: :ja).filename
  end

  test "an unknown locale falls back to English" do
    assert_equal "sagasu-approval-#{@approval.id}-en.pdf", ApprovalDocument.new(@approval, locale: :es).filename
  end
end
