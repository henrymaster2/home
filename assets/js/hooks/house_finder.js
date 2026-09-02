const HouseFinder = {
  mounted() {
    this.init()
  },

  updated() {
    this.cleanup()
    this.init()
  },

  destroyed() {
    this.cleanup()
  },

  init() {
    this.container = this.el.querySelector("#cinematic-scroll")
    this.sections = Array.from(this.el.querySelectorAll(".house-section"))
    this.heroSlides = Array.from(this.el.querySelectorAll(".holo-slide"))
    this.heroIndex = 0

    if (this.container) {
      this.onScroll = () => this.handleScroll()
      this.container.addEventListener("scroll", this.onScroll, { passive: true })
    }

    if (this.heroSlides.length > 1) {
      this.heroTimer = window.setInterval(() => this.advanceHeroSlide(), 4000)
    }
  },

  handleScroll() {
    this.sections.forEach(section => {
      section.toggleAttribute("data-active-section", this.isMostlyVisible(section))
    })
  },

  isMostlyVisible(section) {
    const sectionBox = section.getBoundingClientRect()
    const containerBox = this.container.getBoundingClientRect()
    const visibleTop = Math.max(sectionBox.top, containerBox.top)
    const visibleBottom = Math.min(sectionBox.bottom, containerBox.bottom)
    const visibleHeight = Math.max(0, visibleBottom - visibleTop)

    return visibleHeight >= sectionBox.height * 0.5
  },

  advanceHeroSlide() {
    this.heroSlides[this.heroIndex].classList.remove("active")
    this.heroIndex = (this.heroIndex + 1) % this.heroSlides.length
    this.heroSlides[this.heroIndex].classList.add("active")
  },

  cleanup() {
    if (this.container && this.onScroll) this.container.removeEventListener("scroll", this.onScroll)
    if (this.heroTimer) window.clearInterval(this.heroTimer)

    this.onScroll = null
    this.heroTimer = null
  }
}

export { HouseFinder }
export default HouseFinder
