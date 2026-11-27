# Sagasu demo data. All companies and people are fictional; websites use the reserved .example domain.
# Run: bin/rails db:seed (resets the demo data). AI calls are switched off here: seeds use Sagasu's local matching,
# so the result is the same on every machine.
ENV["SAGASU_AI_DISABLED"] = "1"

puts "Cleaning the database…"
[Approval, Review, GroupSupplier, AiRun, Item, ItemGroup, Project, Supplier, User].each(&:delete_all)

# ---------- Users ----------
puts "Creating users…"
password = "sagasu123"
aiko   = User.create!(name: "Aiko Tanaka",  email: "aiko@sagasu.test",   password: password, role: "buyer")
yuki   = User.create!(name: "Yuki Mori",    email: "yuki@sagasu.test",   password: password, role: "buyer")
daichi = User.create!(name: "Daichi Ono",   email: "daichi@sagasu.test", password: password, role: "buyer")
kenji  = User.create!(name: "Kenji Sato",   email: "kenji@sagasu.test",  password: password, role: "approver")
hiroshi = User.create!(name: "Hiroshi Ito", email: "hiroshi@sagasu.test", password: password, role: "approver")

# ---------- Suppliers ----------
# [name, city, prefecture, delivery areas, monthly capacity, unit, lead time (days), certifications, description]
# nil values are on purpose: Sagasu shows them as "to confirm".
SUPPLIERS = {
  "masonry" => [
    ["Kanto Clayworks", "Kawaguchi", "Saitama", %w[Tokyo Saitama Kanagawa Chiba], 60_000, "bricks", 7,
     ["JIS A 5210", "ISO 9001"], "Fired clay facing bricks and engineering bricks, kiln in Kawaguchi. Weekly deliveries across central Tokyo."],
    ["Musashi Brick Co.", "Tokorozawa", "Saitama", %w[Tokyo Saitama], nil, "bricks", 10, ["JIS A 5210"],
     "Family-run brickworks known for colour-matched facing bricks for façade renovation."],
    ["Tama Masonry Supply", "Hachioji", "Tokyo", %w[Tokyo Kanagawa Yamanashi], 35_000, "bricks", 5, [],
     "Builders' merchant for bricks, concrete blocks and mortar. Same-week delivery in western Tokyo."],
    ["Shonan Block Industries", "Hiratsuka", "Kanagawa", %w[Kanagawa Tokyo Shizuoka], 120_000, "blocks", 12,
     ["JIS A 5406"], "Concrete masonry blocks, retaining wall blocks and paving units."],
    ["Kitakanto Ceramics", "Ashikaga", "Tochigi", %w[Tochigi Gunma Ibaraki Saitama], 45_000, "bricks", nil,
     ["ISO 14001"], "Clay bricks and roof tiles with a recycled-content range."],
    ["Edo Heritage Bricks", "Koto", "Tokyo", [], nil, nil, nil, [],
     "Reclaimed and heritage-style bricks for restoration projects. Small batches."]
  ],
  "concrete" => [
    ["Arakawa Ready-Mix", "Arakawa", "Tokyo", %w[Tokyo], 18_000, "m³", 2, ["JIS A 5308"],
     "Ready-mixed concrete plant serving central and east Tokyo, night pours available."],
    ["Keiyo Cement Trading", "Ichikawa", "Chiba", %w[Chiba Tokyo Ibaraki], 9_000, "t", 4, ["ISO 9001"],
     "Bagged and bulk Portland cement, mortar mixes and grout."],
    ["Sagami Precast", "Atsugi", "Kanagawa", %w[Kanagawa Tokyo], 1_200, "units", 21, ["JIS A 5372"],
     "Precast concrete panels, stairs and U-channels made to order."],
    ["Bando Mortar Works", "Koshigaya", "Saitama", %w[Saitama Tokyo Chiba], nil, "bags", 3, [],
     "Pre-mixed mortars (M2 to M6), repair mortars and tile adhesives."],
    ["Nippon Grout Systems", "Kawasaki", "Kanagawa", ["Nationwide"], 2_500, "t", 6, ["ISO 9001", "ISO 14001"],
     "Non-shrink grouts and specialist concrete repair products."]
  ],
  "steel" => [
    ["Tokyo Bay Steel", "Ota", "Tokyo", %w[Tokyo Kanagawa Chiba], 2_400, "t", 10, ["JIS G 3112", "ISO 9001"],
     "Deformed rebar (SD295 to SD490), cut and bent to schedule."],
    ["Joban Structural", "Hitachi", "Ibaraki", %w[Ibaraki Chiba Tokyo Tochigi], 800, "t", 30, ["JIS G 3136"],
     "H-beams and structural sections, fabrication and shop priming."],
    ["Kanagawa Rebar Center", "Yokohama", "Kanagawa", %w[Kanagawa Tokyo], 1_500, "t", 7, ["JIS G 3112"],
     "Rebar processing and site delivery with crane trucks."],
    ["Chiba Deck & Bolt", "Funabashi", "Chiba", %w[Chiba Tokyo], nil, "t", nil, [],
     "Composite floor deck, high-strength bolts and studs."],
    ["Omiya Steel Trading", "Saitama", "Saitama", %w[Saitama Tokyo Gunma], 1_100, "t", 9, ["ISO 9001"],
     "Stockholder for rebar, plate and light gauge steel."]
  ],
  "timber" => [
    ["Okutama Timber", "Ome", "Tokyo", %w[Tokyo Saitama Yamanashi], 900, "m³", 14, ["FSC", "JAS"],
     "Domestic cedar and cypress, glulam beams and CLT panels."],
    ["Boso Plywood", "Kisarazu", "Chiba", %w[Chiba Tokyo Kanagawa], 40_000, "sheets", 6, ["JAS"],
     "Structural plywood and formwork panels."],
    ["Nikko Wood Products", "Nikko", "Tochigi", %w[Tochigi Tokyo Saitama Ibaraki], nil, "m³", 20, ["FSC"],
     "Kiln-dried lumber and interior wood finishes."],
    ["Yokohama Lumber Yard", "Yokohama", "Kanagawa", %w[Kanagawa Tokyo], 600, "m³", 4, [],
     "Timber merchant: studs, joists, battens and treated timber."]
  ],
  "insulation" => [
    ["Kanto Thermal Materials", "Kumagaya", "Saitama", %w[Saitama Tokyo Gunma Tochigi], 30_000, "m²", 5,
     ["JIS A 9521"], "Glass wool and rock wool insulation for walls and roofs."],
    ["EcoShield Japan", "Sagamihara", "Kanagawa", ["Nationwide"], 50_000, "m²", 8, ["JIS A 9521", "ISO 14001"],
     "XPS and EPS boards, low-GWP foam insulation."],
    ["Tokyo Insulation Supply", "Edogawa", "Tokyo", %w[Tokyo Chiba], nil, "m²", 3, [],
     "Distributor of insulation, vapour barriers and fixings."],
    ["Mito Urethane", "Mito", "Ibaraki", %w[Ibaraki Tochigi Chiba], 12_000, "m²", nil, ["ISO 9001"],
     "Spray urethane foam and PIR panels."]
  ],
  "roofing" => [
    ["Kanto Roof & Waterproof", "Machida", "Tokyo", %w[Tokyo Kanagawa], 20_000, "m²", 10, ["ISO 9001"],
     "Waterproofing membranes, roof sheets and gutters with installation crews."],
    ["Chiba Membrane Systems", "Chiba", "Chiba", %w[Chiba Tokyo Ibaraki], 15_000, "m²", 7, [],
     "Asphalt and TPO membranes, sealants."],
    ["Gunma Tile & Roof", "Takasaki", "Gunma", %w[Gunma Saitama Tochigi], nil, "m²", 15, ["JIS A 5208"],
     "Clay and metal roofing, traditional kawara tiles."],
    ["Shinagawa Sealant Co.", "Shinagawa", "Tokyo", %w[Tokyo Kanagawa Saitama Chiba], 8_000, "cartridges", 2, [],
     "Construction sealants and joint products."]
  ],
  "glazing" => [
    ["Minato Glass Works", "Minato", "Tokyo", %w[Tokyo Kanagawa], 4_000, "m²", 25, ["JIS R 3209"],
     "Insulated glazing units and curtain wall glass."],
    ["Kanagawa Window Systems", "Fujisawa", "Kanagawa", %w[Kanagawa Tokyo Shizuoka], 3_000, "windows", 30,
     ["ISO 9001"], "Aluminium and PVC windows, made to measure."],
    ["Saitama Sash Center", "Kawagoe", "Saitama", %w[Saitama Tokyo], nil, "windows", 21, [],
     "Window sash replacement and glazing repair."]
  ],
  "electrical" => [
    ["Akihabara Cable & Wire", "Chiyoda", "Tokyo", %w[Tokyo Kanagawa Saitama Chiba], 200_000, "m", 3,
     ["JIS C 3605", "ISO 9001"], "Power and data cables, conduit and cable trays."],
    ["Kanto Lighting Supply", "Saitama", "Saitama", %w[Saitama Tokyo Gunma], 15_000, "fixtures", 7, ["PSE"],
     "LED lighting for offices, warehouses and schools."],
    ["Shin-Yokohama Switchgear", "Yokohama", "Kanagawa", %w[Kanagawa Tokyo], 120, "panels", 35, ["JIS C 8480"],
     "Switchboards and distribution panels, made to order."],
    ["Tsukuba Electric Trading", "Tsukuba", "Ibaraki", %w[Ibaraki Chiba Tokyo], nil, "m", 5, [],
     "Electrical wholesaler: breakers, wiring devices, cable."]
  ],
  "plumbing" => [
    ["Kanto Pipe & Valve", "Kawasaki", "Kanagawa", %w[Kanagawa Tokyo Chiba], 50_000, "m", 5, ["JIS K 6741"],
     "PVC and PE pipe, fittings and valves."],
    ["Tokyo Sanitary Supply", "Shibuya", "Tokyo", %w[Tokyo], 1_500, "fixtures", 10, ["ISO 9001"],
     "Toilets, basins and sanitary fittings for commercial buildings."],
    ["Bando Plumbing Wholesale", "Kasukabe", "Saitama", %w[Saitama Tokyo Ibaraki], nil, "m", 4, [],
     "Plumbing wholesaler with next-day delivery."]
  ],
  "hvac" => [
    ["Kanto Air Systems", "Shinagawa", "Tokyo", %w[Tokyo Kanagawa Saitama Chiba], 300, "units", 28, ["ISO 9001"],
     "VRF air conditioning, heat pumps and ventilation units."],
    ["Sagami Duct Works", "Ebina", "Kanagawa", %w[Kanagawa Tokyo], 8_000, "m", 12, [],
     "Galvanised ductwork fabrication and fittings."],
    ["Chiba Ventilation Co.", "Matsudo", "Chiba", %w[Chiba Tokyo], nil, "units", nil, [],
     "Ventilation fans and heat recovery units."]
  ],
  "finishes" => [
    ["Kanto Gypsum Board", "Ichihara", "Chiba", %w[Chiba Tokyo Kanagawa Saitama], 60_000, "boards", 4, ["JIS A 6901"],
     "Plasterboard and ceiling boards, fire-rated ranges."],
    ["Ginza Interior Materials", "Chuo", "Tokyo", %w[Tokyo], 10_000, "m²", 9, ["ISO 14001"],
     "Vinyl flooring, carpet tiles and wall coverings."],
    ["Tama Paint & Coatings", "Tachikawa", "Tokyo", %w[Tokyo Kanagawa Saitama], 25_000, "L", 3, ["JIS K 5663"],
     "Interior and exterior paints, primers and coatings."],
    ["Mashiko Tile Studio", "Mashiko", "Tochigi", %w[Tochigi Tokyo], nil, "m²", 30, [],
     "Handmade ceramic tiles for feature walls."]
  ],
  "aggregates" => [
    ["Chichibu Aggregates", "Chichibu", "Saitama", %w[Saitama Tokyo Gunma], 40_000, "t", 2, ["JIS A 5005"],
     "Crushed stone, gravel and concrete sand from Chichibu quarries."],
    ["Boso Sand & Gravel", "Kimitsu", "Chiba", %w[Chiba Tokyo Kanagawa], 30_000, "t", 3, [],
     "River sand, gravel and backfill materials."],
    ["Kanto Asphalt Plant", "Kawasaki", "Kanagawa", %w[Kanagawa Tokyo], 15_000, "t", 1, ["JIS K 2207"],
     "Hot-mix asphalt for paving and car parks."]
  ]
}.freeze

# Geocoded once by hand: "City, Prefecture" => [latitude, longitude]. Kept in the seeds so
# db:seed never calls a geocoding service; the supplier map works out of the box.
CITY_COORDINATES = {
  "Kawaguchi, Saitama" => [35.8077, 139.7241], "Tokorozawa, Saitama" => [35.7996, 139.4687],
  "Hachioji, Tokyo" => [35.6570, 139.3239], "Hiratsuka, Kanagawa" => [35.3356, 139.3422],
  "Ashikaga, Tochigi" => [36.3402, 139.4497], "Koto, Tokyo" => [35.6667, 139.8167],
  "Arakawa, Tokyo" => [35.7361, 139.7813], "Ichikawa, Chiba" => [35.7220, 139.9310],
  "Atsugi, Kanagawa" => [35.4433, 139.3625], "Koshigaya, Saitama" => [35.8911, 139.7909],
  "Kawasaki, Kanagawa" => [35.5309, 139.7030], "Ota, Tokyo" => [35.5613, 139.7160],
  "Hitachi, Ibaraki" => [36.5991, 140.6515], "Yokohama, Kanagawa" => [35.4437, 139.6380],
  "Funabashi, Chiba" => [35.6947, 139.9825], "Saitama, Saitama" => [35.8617, 139.6455],
  "Ome, Tokyo" => [35.7880, 139.2750], "Kisarazu, Chiba" => [35.3761, 139.9168],
  "Nikko, Tochigi" => [36.7199, 139.6982], "Kumagaya, Saitama" => [36.1474, 139.3886],
  "Sagamihara, Kanagawa" => [35.5712, 139.3732], "Edogawa, Tokyo" => [35.7066, 139.8682],
  "Mito, Ibaraki" => [36.3659, 140.4713], "Machida, Tokyo" => [35.5462, 139.4386],
  "Chiba, Chiba" => [35.6073, 140.1063], "Takasaki, Gunma" => [36.3228, 139.0032],
  "Shinagawa, Tokyo" => [35.6092, 139.7302], "Minato, Tokyo" => [35.6580, 139.7516],
  "Fujisawa, Kanagawa" => [35.3393, 139.4910], "Kawagoe, Saitama" => [35.9251, 139.4858],
  "Chiyoda, Tokyo" => [35.6940, 139.7538], "Tsukuba, Ibaraki" => [36.0835, 140.0766],
  "Shibuya, Tokyo" => [35.6580, 139.7016], "Kasukabe, Saitama" => [35.9753, 139.7523],
  "Ebina, Kanagawa" => [35.4464, 139.3908], "Matsudo, Chiba" => [35.7876, 139.9032],
  "Ichihara, Chiba" => [35.4980, 140.1156], "Chuo, Tokyo" => [35.6706, 139.7720],
  "Tachikawa, Tokyo" => [35.7142, 139.4075], "Mashiko, Tochigi" => [36.4671, 140.0964],
  "Chichibu, Saitama" => [35.9918, 139.0856], "Kimitsu, Chiba" => [35.3304, 139.9025]
}.freeze

puts "Creating suppliers…"
code = 1000
SUPPLIERS.each do |category, rows|
  rows.each do |name, city, prefecture, areas, capacity, unit, lead_time, certifications, description|
    code += 1
    slug = name.downcase.gsub(/[^a-z0-9]+/, "-").delete_suffix("-")
    latitude, longitude = CITY_COORDINATES.fetch("#{city}, #{prefecture}")
    Supplier.create!(
      name: name, category: category, city: city, prefecture: prefecture, country: "Japan",
      latitude: latitude, longitude: longitude,
      delivery_areas: areas, monthly_capacity: capacity, capacity_unit: (unit if capacity), lead_time_days: lead_time,
      certifications: certifications, description: description,
      erp_vendor_code: "V-#{code}", tax_id: (format("T%013d", 4_011_001_000_000 + (code * 7919)) if code.odd?),
      website: "https://www.#{slug}.example", source_url: ("https://www.#{slug}.example/catalogue" if capacity),
      # Fictional contacts on most suppliers; every fourth has no email, so the
      # invitations page can show its "no email address" state.
      contact_name: (["Sato", "Suzuki", "Tanaka", "Yamada"].sample + " " + ["Ken", "Aya", "Ryo", "Mio"].sample if code.even?),
      email: ("sales@#{slug}.example" unless code % 4 == 0),
      phone: ("03-%04d-%04d" % [code, (code * 37) % 10_000] if code.even?)
    )
  end
end
supplier = ->(name) { Supplier.find_by!(name: name) }

# ---------- Reviews ----------
puts "Creating reviews…"
REVIEWS = [
  [aiko, "Kanto Clayworks", 5,
   "Delivered 48,000 facing bricks over six weeks with no breakage claims. Colour batches were consistent.", "verified"],
  [yuki, "Kanto Clayworks", 4,
   "Good quality. Two deliveries arrived a day late during Golden Week, they warned us in advance.", "verified"],
  [daichi, "Kanto Clayworks", 2, "Phone support was slow when I asked for a quote.", "unverified"], # one negative observation: shown, never a blacklist
  [aiko, "Musashi Brick Co.", 5,
   "Excellent colour matching for the Ochanomizu façade repair. Capacity is limited, order early.", "verified"],
  [yuki, "Tama Masonry Supply", 4, "Reliable for blocks and mortar, flexible delivery slots in Hachioji.", "verified"],
  [daichi, "Shonan Block Industries", 3, "Price was fine but the paperwork for the JIS certificates took two weeks.",
   "unverified"],
  [aiko, "Arakawa Ready-Mix", 5, "Night pours went smoothly, the dispatcher speaks good English.", "verified"],
  [yuki, "Keiyo Cement Trading", 4, "Competitive on bagged cement, minimum order 10 t.", "verified"],
  [daichi, "Bando Mortar Works", 2, "One batch of M4 mortar seemed too dry. Not confirmed by lab test.", "disputed"],
  [aiko, "Tokyo Bay Steel", 5, "Bending schedule followed exactly, mill certificates sent with each truck.",
   "verified"],
  [yuki, "Kanagawa Rebar Center", 4, "Fast for small rebar orders in Yokohama.", "verified"],
  [daichi, "Chiba Deck & Bolt", 3, "Could not get a clear monthly capacity figure from them.", "unverified"],
  [aiko, "Okutama Timber", 5, "Beautiful cedar for the school entrance. FSC chain of custody documents complete.",
   "verified"],
  [yuki, "Boso Plywood", 4, "Formwork plywood good value, delivery needs two days notice.", "verified"],
  [aiko, "Kanto Thermal Materials", 4, "Glass wool delivered on time for the warehouse roof.", "verified"],
  [daichi, "EcoShield Japan", 5, "Low-GWP XPS boards helped our environmental rating.", "verified"],
  [yuki, "Kanto Roof & Waterproof", 4, "Membrane plus installation crew, good warranty terms.", "verified"],
  [aiko, "Minato Glass Works", 3, "High quality but 25-day lead time is real, plan for it.", "verified"],
  [daichi, "Akihabara Cable & Wire", 5, "Cable delivered next morning for an urgent change order.", "verified"],
  [yuki, "Kanto Lighting Supply", 4, "LED fixtures fine, samples sent quickly.", "unverified"],
  [aiko, "Kanto Pipe & Valve", 4, "Large PVC order handled well.", "verified"],
  [daichi, "Kanto Air Systems", 4, "VRF units on time, commissioning support included.", "verified"],
  [yuki, "Kanto Gypsum Board", 5, "Fire-rated boards always in stock.", "verified"],
  [aiko, "Chichibu Aggregates", 4, "Consistent crushed stone grading.", "verified"]
].freeze
REVIEWS.each do |author, name, rating, comment, status|
  Review.create!(user: author, supplier: supplier.call(name), rating: rating, comment: comment, status: status,
                 visibility: "organization")
end

# ---------- Projects ----------
puts "Creating projects…"

# 1. Fresh project for the live demo: materials only, AI grouping not run yet
Project.create!(
  user: aiko, title: "Shinjuku office tower, façade works", erp_rfq: "RFQ-2026-118",
  client_name: "Aoyama Development", client_area: "Tokyo", budget_amount: 85_000_000, budget_currency: "JPY",
  scope: "Facing bricks delivered in Tokyo, about 50,000 per month from April, plus mortar and façade insulation.",
  materials_text: <<~LIST
    Facing bricks 215x102x65, red; 50000; pcs
    Engineering bricks class B; 8000; pcs
    Mortar mix M4; 300; bag
    Portland cement 25kg; 400; bag
    Glass wool insulation 100mm; 1200; m2
    Waterproof membrane for parapets; 450; m2
  LIST
)

# Helper: group with local AI, suggest suppliers, then select some like a buyer would
build_list = lambda do |project, buyer, picks:, declines: {}|
  Ai::ItemGrouper.new(project: project, user: buyer).call
  project.item_groups.reload.each do |group|
    Ai::SupplierRecommender.new(item_group: group, user: buyer).call
    group.group_suppliers.reload.each do |link|
      if picks.include?(link.supplier.name)
        link.update!(selected: true)
      elsif (reason = declines[link.supplier.name])
        link.update!(selected: false, feedback_reason: reason)
      end
    end
  end
end

# 2. Waiting for Kenji's approval
warehouse = Project.create!(
  user: aiko, title: "Yokohama logistics warehouse", erp_rfq: "RFQ-2026-097",
  client_name: "Minato Logistics", client_area: "Kanagawa", budget_amount: 210_000_000, budget_currency: "JPY",
  scope: "Steel-frame warehouse in Yokohama: rebar and structural steel, roof insulation and LED lighting.",
  materials_text: <<~LIST
    Rebar D13 SD345; 40; t
    Rebar D19 SD345; 65; t
    H-beam 400x200; 120; t
    Glass wool roof insulation; 6000; m2
    LED high-bay lighting; 220; units
  LIST
)
build_list.call(warehouse, aiko, picks: ["Tokyo Bay Steel", "Kanagawa Rebar Center", "Kanto Thermal Materials", "EcoShield Japan", "Kanto Lighting Supply", "Akihabara Cable & Wire"],
                                 declines: { "Chiba Deck & Bolt" => "Capacity too low" })
warehouse.submit_for_approval!(approver: kenji,
                               comment: "Two steel bidders with Yokohama delivery. Lighting needs a second quote.")

# 3. Approved, with its history
school = Project.create!(
  user: yuki, title: "Saitama elementary school renovation", erp_rfq: "RFQ-2026-064",
  client_name: "Saitama City Education Board", client_area: "Saitama", budget_amount: 64_000_000, budget_currency: "JPY",
  scope: "Interior renovation: plasterboard, flooring, paint and new timber entrance.",
  materials_text: <<~LIST
    Fire-rated plasterboard 12.5mm; 2400; boards
    Vinyl flooring for classrooms; 1800; m2
    Interior paint, washable; 900; L
    Cedar glulam beams; 18; m3
  LIST
)
build_list.call(school, yuki,
                picks: ["Kanto Gypsum Board", "Ginza Interior Materials", "Tama Paint & Coatings", "Okutama Timber"])
school.submit_for_approval!(approver: kenji, comment: "All bidders deliver to Saitama.")
school.approvals.last.decide!(decision: "approved", comment: "Good list. Proceed with the RFQ.")

# 4. Returned by the approver with a comment
chiba = Project.create!(
  user: aiko, title: "Chiba residential block B", erp_rfq: "RFQ-2026-131",
  client_name: "Keiyo Housing", client_area: "Chiba", budget_amount: 120_000_000, budget_currency: "JPY",
  scope: "Six-storey residential block: ready-mix concrete, rebar, windows and plumbing.",
  materials_text: <<~LIST
    Ready-mix concrete 24-18-20; 2600; m3
    Rebar D16 SD345; 90; t
    Aluminium windows, double glazed; 140; windows
    PVC drain pipe 100mm; 1800; m
  LIST
)
build_list.call(chiba, aiko,
                picks: ["Arakawa Ready-Mix", "Tokyo Bay Steel", "Kanagawa Window Systems", "Kanto Pipe & Valve"])
chiba.submit_for_approval!(approver: hiroshi)
chiba.approvals.last.decide!(decision: "returned",
                             comment: "Arakawa does not deliver to Chiba. Please add a concrete supplier based in Chiba.")

# A project-only review, visible only to people on the Chiba project
Review.create!(user: aiko, supplier: supplier.call("Keiyo Cement Trading"), project: chiba, visibility: "project", rating: 4,
               comment: "Offered a site visit for the Chiba block. Pricing confidential until the tender closes.")

puts "Done: #{User.count} users, #{Supplier.count} suppliers, #{Project.count} projects, #{Review.count} reviews, #{AiRun.count} AI runs."
puts "Log in with aiko@sagasu.test (buyer) or kenji@sagasu.test (approver), password #{password}."
