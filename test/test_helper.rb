ENV["RAILS_ENV"] ||= "test"
# Tests never call OpenAI: the AI services use Sagasu's local matching
ENV["SAGASU_AI_DISABLED"] = "1"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    # Small builders instead of fixtures: each test states the data it needs
    def create_user(role: "buyer", name: "Test #{role.capitalize}")
      User.create!(name: name, role: role, email: "#{SecureRandom.hex(4)}@sagasu.test", password: "sagasu123")
    end

    def create_supplier(name: "Supplier #{SecureRandom.hex(2)}", category: "masonry", **attributes)
      Supplier.create!({ name: name, category: category, prefecture: "Tokyo", city: "Koto",
                         delivery_areas: ["Tokyo"], monthly_capacity: 50_000, capacity_unit: "bricks",
                         lead_time_days: 7, certifications: ["JIS A 5210"] }.merge(attributes))
    end

    def create_project(user:, materials: "Facing bricks; 50000; pcs\nMortar mix; 300; bag", **attributes)
      Project.create!({ user: user, title: "Test project", client_area: "Tokyo", materials_text: materials }.merge(attributes))
    end

    # A project with one group, all items in it and one selected supplier: ready for approval
    def create_ready_project(user:)
      project = create_project(user: user)
      group = project.item_groups.create!(title: "Masonry")
      project.items.update_all(item_group_id: group.id)
      group.group_suppliers.create!(supplier: create_supplier, selected: true)
      project.reload
    end
  end
end

module SignInHelper
  def sign_in_as(user)
    delete destroy_user_session_path
    post user_session_path, params: { user: { email: user.email, password: "sagasu123" } }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
