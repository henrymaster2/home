const HouseFinder = {
  mounted() {
    this.init()

    // -------------------------
    // Global theme
    // -------------------------
    const savedTheme = localStorage.getItem("theme")

    if (savedTheme === "dark" || savedTheme === "light") {
      this.applyTheme(savedTheme)
      this.pushEvent("restore_theme", { theme: savedTheme })
    }

    this.handleEvent("set_global_theme", ({ theme }) => {
      if (theme !== "dark" && theme !== "light") return

      localStorage.setItem("theme", theme)
      this.applyTheme(theme)
    })

    // -------------------------
    // Clipboard
    // -------------------------
    this.handleEvent("copy-to-clipboard", async ({ text }) => {
      try {
        // HTTPS / secure context
        if (navigator.clipboard && window.isSecureContext) {
          await navigator.clipboard.writeText(text)
          console.log("✅ Copied!")
          return
        }

        // HTTP / mobile fallback
        const textarea = document.createElement("textarea")

        textarea.value = text
        textarea.style.position = "fixed"
        textarea.style.left = "-9999px"
        textarea.style.top = "0"
        textarea.style.opacity = "0"

        document.body.appendChild(textarea)

        textarea.focus()
        textarea.select()
        textarea.setSelectionRange(0, textarea.value.length)

        const success = document.execCommand("copy")

        textarea.remove()

        if (success) {
          console.log("✅ Copied with fallback")
        } else {
          console.error("❌ Fallback copy failed")
        }
      } catch (err) {
        console.error("❌ Copy failed:", err)
      }
    })
  },

  updated() {
    this.cleanup()
    this.init()
  },

  destroyed() {
    this.cleanup()
  },

  applyTheme(theme) {
    document.documentElement.dataset.theme = theme
  },

  init() {
    this.container = this.el.querySelector("#cinematic-scroll")
    this.sections = Array.from(
      this.el.querySelectorAll(".house-section")
    )

    this.heroSlides = Array.from(
      this.el.querySelectorAll(".holo-slide")
    )

    this.heroIndex = 0

    if (this.container) {
      this.onScroll = () => this.handleScroll()

      this.container.addEventListener(
        "scroll",
        this.onScroll,
        { passive: true }
      )
    }

    if (this.heroSlides.length > 1) {
      this.heroTimer = window.setInterval(
        () => this.advanceHeroSlide(),
        4000
      )
    }
  },

  handleScroll() {
    this.sections.forEach(section => {
      section.toggleAttribute(
        "data-active-section",
        this.isMostlyVisible(section)
      )
    })
  },

  isMostlyVisible(section) {
    const sectionBox = section.getBoundingClientRect()
    const containerBox = this.container.getBoundingClientRect()

    const visibleTop = Math.max(
      sectionBox.top,
      containerBox.top
    )

    const visibleBottom = Math.min(
      sectionBox.bottom,
      containerBox.bottom
    )

    const visibleHeight = Math.max(
      0,
      visibleBottom - visibleTop
    )

    return visibleHeight >= sectionBox.height * 0.5
  },

  advanceHeroSlide() {
    this.heroSlides[this.heroIndex]
      .classList.remove("active")

    this.heroIndex =
      (this.heroIndex + 1) % this.heroSlides.length

    this.heroSlides[this.heroIndex]
      .classList.add("active")
  },

  cleanup() {
    if (this.container && this.onScroll) {
      this.container.removeEventListener(
        "scroll",
        this.onScroll
      )
    }

    if (this.heroTimer) {
      window.clearInterval(this.heroTimer)
    }

    this.onScroll = null
    this.heroTimer = null
  }
}

export { HouseFinder }
export default HouseFinder