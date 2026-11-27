class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { buyer: "buyer", approver: "approver" }, default: "buyer", validate: true

  has_many :projects, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :ai_runs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, inverse_of: :actor,
                                 dependent: :nullify
  has_many :approvals_to_decide, class_name: "Approval", foreign_key: :approver_id,
                                 inverse_of: :approver, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 80 }

  def first_name
    name.split.first
  end

  def initials
    name.split.first(2).map { |part| part[0] }.join.upcase
  end

  def pending_approvals_count
    approver? ? approvals_to_decide.pending.count : 0
  end
end
