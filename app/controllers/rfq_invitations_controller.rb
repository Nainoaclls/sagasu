# After approval, the buyer contacts each selected supplier from the frozen snapshot.
# The text is rebuilt on the fly (RfqInvitationBuilder); only the "sent" flag is stored.
# Nothing is emailed by the app: the buyer uses the mailto link or copies the text.
class RfqInvitationsController < ApplicationController
  before_action :set_approval

  def index
    authorize @approval, policy_class: RfqInvitationPolicy
    policy_scope(RfqInvitation).where(approval: @approval).load
    @invitations = snapshot_suppliers.map do |supplier|
      { supplier: supplier,
        invitation: invitation_for(supplier),
        builder: RfqInvitationBuilder.new(approval: @approval, supplier: supplier) }
    end
  end

  def show
    load_supplier_and_invitation
    authorize @invitation, policy_class: RfqInvitationPolicy
    @builder = RfqInvitationBuilder.new(approval: @approval, supplier: @supplier)
  end

  # The buyer confirms they contacted the supplier (by email, phone, …)
  def mark_sent
    load_supplier_and_invitation
    authorize @invitation, policy_class: RfqInvitationPolicy

    @invitation.save! if @invitation.new_record?
    @invitation.mark_sent!(by: current_user)
    redirect_to approval_rfq_invitations_path(@approval),
                notice: t("rfq_invitations.flash.sent", name: @supplier.name), status: :see_other
  end

  private

  def set_approval
    @approval = Approval.find(params[:approval_id])
  end

  # Suppliers on the frozen snapshot, in group order
  def snapshot_suppliers
    ids = @approval.snapshot_groups.flat_map { |group| Array(group["suppliers"]).map { |s| s["id"] } }.uniq
    Supplier.where(id: ids).sort_by { |supplier| ids.index(supplier.id) }
  end

  def invitation_for(supplier)
    @approval.rfq_invitations.find_or_initialize_by(supplier: supplier)
  end

  def load_supplier_and_invitation
    @supplier = snapshot_suppliers.find { |supplier| supplier.id == params[:id].to_i }
    raise ActiveRecord::RecordNotFound unless @supplier

    @invitation = invitation_for(@supplier)
  end
end
