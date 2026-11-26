module SupplierComparisonsHelper
  # A comparison cell: the value, or "to confirm" with an icon (never an empty cell or a zero)
  def compare_value(value)
    return value if value.present?

    safe_join([icon("fa-circle-question"), " #{t('helpers.to_confirm')}"])
  end
end
