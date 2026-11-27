class NotificationPolicy < ApplicationPolicy
  def index?
    true
  end

  # A notification is for one person only
  def show?
    record.user_id == user.id
  end

  def mark_all_read?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
