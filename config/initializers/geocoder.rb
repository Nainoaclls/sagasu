# Supplier geocoding (see Supplier#should_geocode?). Seeds carry their own coordinates,
# so db:seed never calls the network.
if Rails.env.test?
  # No network in tests: every lookup answers "no result" unless a test stubs an address
  Geocoder.configure(lookup: :test)
  Geocoder::Lookup::Test.set_default_stub([])
else
  Geocoder.configure(
    lookup: :nominatim,
    timeout: 5,
    units: :km,
    http_headers: { "User-Agent" => "Sagasu/1.0 (procurement demo app)" }
  )
end
