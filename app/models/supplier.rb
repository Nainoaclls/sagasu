class Supplier < ApplicationRecord
  include PgSearch::Model

  NATIONWIDE = "Nationwide".freeze

  has_many :reviews, dependent: :destroy
  has_many :group_suppliers, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 120 }
  validates :category, inclusion: { in: MaterialCategory.keys }
  validates :monthly_capacity, :lead_time_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  # Full-string match: only http(s) links, no "javascript:" or spaces (they are rendered as hrefs)
  validates :website, :source_url, format: { with: %r{\Ahttps?://[^\s<>"]+\z}i }, allow_blank: true

  pg_search_scope :search_text,
                  against: { name: "A", category: "B", city: "B", prefecture: "B", description: "C" },
                  using: { tsearch: { prefix: true, any_word: true } }

  scope :in_category, ->(category) { category.present? ? where(category: category) : all }
  scope :delivering_to, lambda { |area|
    next all if area.blank?

    where("prefecture = :area OR :area = ANY(delivery_areas) OR :nation = ANY(delivery_areas)",
          area: area, nation: NATIONWIDE)
  }

  # Supplier search page: text search ranked by relevance, otherwise alphabetical
  def self.filter_by(query:, category:, area:)
    suppliers = in_category(category).delivering_to(area)
    query.present? ? suppliers.search_text(query) : suppliers.order(:name)
  end

  def category_label
    MaterialCategory.label(category)
  end

  def location
    [city, prefecture].compact_blank.join(", ").presence || country
  end

  def delivers_to?(area)
    return false if area.blank?

    prefecture == area || delivery_areas.include?(area) || delivery_areas.include?(NATIONWIDE)
  end

  def capacity_label
    return unless monthly_capacity

    "#{ActiveSupport::NumberHelper.number_to_delimited(monthly_capacity)} #{capacity_unit} / month".squish
  end

  # Evidence the buyer still has to confirm with the supplier before contacting them.
  def missing_details
    [
      ("Monthly capacity" if monthly_capacity.nil?),
      ("Lead time" if lead_time_days.nil?),
      ("Delivery area" if delivery_areas.empty?),
      ("Certifications" if certifications.empty?)
    ].compact
  end
end
