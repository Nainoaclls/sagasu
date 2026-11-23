# Material categories used across Sagasu: supplier specialties, AI grouping
# fallback and supplier filters. A plain Ruby object, not a database table.
class MaterialCategory
  CATALOG = {
    "masonry" => { label: "Masonry & bricks", icon: "fa-cubes-stacked",
                   keywords: %w[brick bricks block blocks masonry mortar clay] },
    "concrete" => { label: "Concrete & cement", icon: "fa-trowel",
                    keywords: %w[concrete cement ready-mix readymix precast grout screed] },
    "steel" => { label: "Structural steel & rebar", icon: "fa-industry",
                 keywords: %w[steel rebar beam h-beam column deck bolt bolts girder] },
    "timber" => { label: "Timber & wood",             icon: "fa-tree",
                  keywords: %w[timber wood wooden plywood lumber cedar laminated clt glulam] },
    "insulation" => { label: "Insulation", icon: "fa-temperature-half",
                      keywords: %w[insulation wool foam eps xps urethane] },
    "roofing" => { label: "Roofing & waterproofing", icon: "fa-house-chimney",
                   keywords: %w[roof roofing waterproof waterproofing membrane gutter sealant] },
    "glazing" => { label: "Windows & glazing", icon: "fa-border-all",
                   keywords: %w[window windows glass glazing sash curtain-wall] },
    "electrical" => { label: "Electrical", icon: "fa-bolt",
                      keywords: %w[cable cables wire wiring electrical lighting led breaker conduit switchboard] },
    "plumbing" => { label: "Plumbing", icon: "fa-faucet",
                    keywords: %w[pipe pipes pvc valve valves plumbing fitting fittings drain toilet sink] },
    "hvac" => { label: "HVAC", icon: "fa-fan",
                keywords: %w[hvac duct ducts air-conditioning ventilation fan heat-pump chiller] },
    "finishes" => { label: "Interior finishes", icon: "fa-paint-roller",
                    keywords: %w[gypsum plasterboard paint flooring tile tiles ceiling wallpaper vinyl carpet] },
    "aggregates" => { label: "Aggregates & earthworks", icon: "fa-mountain",
                      keywords: %w[sand gravel aggregate aggregates crushed stone soil asphalt] }
  }.freeze

  OTHER = "other".freeze

  def self.keys
    CATALOG.keys
  end

  def self.label(key)
    CATALOG.dig(key, :label) || "Other materials"
  end

  def self.icon(key)
    CATALOG.dig(key, :icon) || "fa-box"
  end

  def self.options
    CATALOG.map { |key, data| [data[:label], key] }
  end

  # Best category for a free-text description, by keyword hits. "other" when nothing matches.
  def self.classify(text)
    words = text.to_s.downcase.gsub(/[^a-z0-9\- ]/, " ").split
    return OTHER if words.empty?

    scores = CATALOG.transform_values { |data| (words & data[:keywords]).size }
    best, score = scores.max_by { |_key, value| value }
    score.positive? ? best : OTHER
  end
end
