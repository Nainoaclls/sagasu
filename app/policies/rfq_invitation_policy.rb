class RfqInvitationPolicy < ApplicationPolicy
  # Invitations belong to the buyer who owns the project, once the approval is approved.
  # The record is the Approval on index, an RfqInvitation on show/mark_sent.
  def index?
    owner_of_approved?
  end

  def show?
    owner_of_approved?
  end

  def mark_sent?
    owner_of_approved?
  end

  private

  def approval
    record.is_a?(Approval) ? record : record.approval
  end

  def owner_of_approved?
    approval.approved? && approval.project.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(approval: Approval.where(project: Project.where(user: user)))
    end
  end
end
