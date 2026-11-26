class SupplierPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # Buyers keep the company's supplier records; approvers only read them.
  def create?
    user.buyer?
  end

  def update?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
