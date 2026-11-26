# Turns a pasted material list into item attributes.
#
# Accepted lines (one material per line):
#   Red clay bricks; 50000; pcs
#   Red clay bricks | 50,000 | pcs
#   MAT-0042<TAB>Red clay bricks<TAB>50000<TAB>pcs   (copied from Excel or the ERP)
#   50,000 pcs red clay bricks
#   Red clay bricks x 50k pcs
#   Red clay bricks                                   (quantity left empty)
class MaterialListParser
  MAX_LINES = 200
  SEPARATOR = /\t|;|\|/
  # "50000", "50,000", "50k", and thousands grouped with a space as written in French or Japanese ("47 000")
  NUMBER = /\d{1,3}(?:[   ]\d{3})+|\d[\d,.]*k?/i
  # Units that mean "how many". Specs such as "100mm" or "D13" stay in the description.
  UNIT = Regexp.union(
    %w[pcs pc pieces units unit ea bags bag sacks sack t tons ton tonnes tonne kg m m2 m² sqm m3 m³ l
       liters liter litres litre sets set rolls roll sheets sheet boxes box pallets pallet
       lengths length coils coil lots lot]
      .sort_by { |unit| -unit.length }
  )
  QTY_FIRST = /\A(?<qty>#{NUMBER})\s*(?<unit>#{UNIT})?\s+(?<desc>[^\d].+)\z/i
  QTY_LAST = /\A(?<desc>.+?)\s+(?:x|×|:|-)?\s*(?<qty>#{NUMBER})\s*(?<unit>#{UNIT})?\z/i
  ERP_CODE = %r{\A[A-Z0-9][A-Z0-9\-_./]{3,}\z}

  def self.parse(text)
    new(text).parse
  end

  def initialize(text)
    @lines = text.to_s.lines.map(&:strip).reject(&:blank?).first(MAX_LINES)
  end

  def parse
    @lines.filter_map { |line| parse_line(line) }
  end

  private

  def parse_line(line)
    attributes = line.match?(SEPARATOR) ? parse_columns(line) : parse_free_text(line)
    return if attributes[:description].blank?

    attributes[:description] = attributes[:description].squish.first(255)
    attributes
  end

  def parse_columns(line)
    cells = line.split(SEPARATOR).map(&:strip)
    erp = cells.first.match?(ERP_CODE) && cells.size >= 3 ? cells.shift : nil
    {
      erp_material: erp,
      description: cells[0],
      quantity: parse_number(cells[1]),
      unit_of_measure: cells[2].presence
    }
  end

  def parse_free_text(line)
    match = line.match(QTY_FIRST) || line.match(QTY_LAST)
    return { description: line } unless match

    { description: match[:desc], quantity: parse_number(match[:qty]), unit_of_measure: match[:unit] }
  end

  def parse_number(value)
    return if value.blank?

    cleaned = value.to_s.downcase.gsub(/[,\s  ]/, "")
    multiplier = cleaned.end_with?("k") ? 1000 : 1
    number = cleaned.delete("k")
    return unless number.match?(/\A\d+(\.\d+)?\z/)

    BigDecimal(number) * multiplier
  end
end
