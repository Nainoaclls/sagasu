# Builds the RFQ invitation email for one supplier from an approval's frozen snapshot:
# only the groups where that supplier appears, with the quantities as they were at
# submission time — never the current (editable) project data. Plain rendering, no AI.
class RfqInvitationBuilder
  # Raised when the supplier is on none of the snapshot groups: no list, no email.
  class MissingMaterialList < StandardError; end

  def initialize(approval:, supplier:)
    @approval = approval
    @supplier = supplier
  end

  def rfq_reference
    approval.project.erp_rfq.presence || I18n.t("rfq_invitations.default_reference")
  end

  def project_title
    approval.snapshot["title"].presence || approval.project.title
  end

  def buyer_name
    approval.snapshot["buyer"].presence || approval.project.user.name
  end

  # The snapshot groups this supplier belongs to (each with its frozen items)
  def groups
    @groups ||= approval.snapshot_groups.select do |group|
      Array(group["suppliers"]).any? { |entry| entry["id"] == supplier.id }
    end
  end

  # One line per item: "- description — quantity unit". Mandatory in the body.
  def material_list
    groups.flat_map do |group|
      Array(group["items"]).map do |item|
        "- #{item['description']} — #{[item['quantity'], item['unit']].compact_blank.join(' ')}"
      end
    end.join("\n")
  end

  def subject
    I18n.t("rfq_invitations.subject", rfq_reference: rfq_reference, project_title: project_title)
  end

  def body
    list = material_list
    raise MissingMaterialList, "supplier ##{supplier.id} is on no group of approval ##{approval.id}" if list.blank?

    I18n.t("rfq_invitations.body", supplier_name: supplier.name, rfq_reference: rfq_reference,
                                   project_title: project_title, material_list: list, buyer_name: buyer_name)
  end

  private

  attr_reader :approval, :supplier
end
