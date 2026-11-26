import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

// Mapbox map of supplier locations. The container carries the public token and the
// markers as JSON (see suppliers/_map). Follows the light/dark theme via the basemap
// light preset.
export default class extends Controller {
  static values = {
    token: String,
    markers: Array, // [{ name, location, url, latitude, longitude }]
    zoom: { type: Number, default: 10 }
  }

  connect() {
    mapboxgl.accessToken = this.tokenValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/standard",
      attributionControl: { compact: true }
    })
    this.map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), "bottom-right")

    this.themeObserver = new MutationObserver(() => this.applyTheme())
    this.themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["data-bs-theme"] })

    this.map.on("load", () => {
      this.loaded = true
      this.applyTheme()
      this.markersValue.forEach((supplier) => this.addMarker(supplier))
      this.fitToMarkers()
    })
  }

  disconnect() {
    this.themeObserver?.disconnect()
    this.map?.remove()
  }

  applyTheme() {
    if (!this.loaded) return
    const dark = document.documentElement.dataset.bsTheme === "dark"
    this.map.setConfigProperty("basemap", "lightPreset", dark ? "dark" : "day")
  }

  addMarker(supplier) {
    const popup = new mapboxgl.Popup({ offset: 16, closeButton: false })
      .setDOMContent(this.popupContent(supplier))
    new mapboxgl.Marker({ color: "#326273" })
      .setLngLat([supplier.longitude, supplier.latitude])
      .setPopup(popup)
      .addTo(this.map)
  }

  // DOM nodes, not HTML strings: supplier names never become markup
  popupContent(supplier) {
    const wrapper = document.createElement("div")
    const name = document.createElement("a")
    name.href = supplier.url
    name.textContent = supplier.name
    name.className = "fw-bold"
    const location = document.createElement("div")
    location.textContent = supplier.location
    location.className = "sg-caption"
    wrapper.append(name, location)
    return wrapper
  }

  fitToMarkers() {
    const points = this.markersValue
    if (points.length === 0) return
    if (points.length === 1) {
      this.map.setCenter([points[0].longitude, points[0].latitude])
      this.map.setZoom(this.zoomValue)
      return
    }
    const bounds = new mapboxgl.LngLatBounds()
    points.forEach((point) => bounds.extend([point.longitude, point.latitude]))
    this.map.fitBounds(bounds, { padding: 48, maxZoom: 11 })
  }
}
