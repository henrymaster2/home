const HouseCardCycle = {
  mounted() {
    this.currentKey = this.el.dataset.housesKey;
    this.init();
  },

  updated() {
    const newKey = this.el.dataset.housesKey;
    if (newKey !== this.currentKey) {
      this.currentKey = newKey;
      this.cleanup();
      this.init();
    }
  },

  destroyed() {
    this.cleanup();
  },

  init() {
    this.houses = Array.from(this.el.querySelectorAll('[data-house]'));
    if (!this.houses.length) return;

    this.houseIndex = 0;
    this.houseDuration = 6000; // ms each house stays on stage
    this.houseFrame = null;
    this.imageFrame = null;

    this.setActiveHouse(0);
    this.startHouseTimer();
  },

  setActiveHouse(index) {
    if (this.imageFrame) cancelAnimationFrame(this.imageFrame);

    this.houses.forEach((house, i) => {
      const isCurrent = i === index;
      house.style.opacity = isCurrent ? '1' : '0';
      house.style.zIndex = isCurrent ? '20' : '10';
      house.style.pointerEvents = isCurrent ? 'auto' : 'none';
    });

    const activeHouse = this.houses[index];
    const images = Array.from(activeHouse.querySelectorAll('[data-house-image]'));
    const bars = Array.from(activeHouse.querySelectorAll('[data-house-progress]'));
    this.startImageCycle(images, bars);
  },

  startImageCycle(images, bars) {
    if (!images.length) return;
    const showImage = (i) =>
      images.forEach((img, idx) => (img.style.opacity = idx === i ? '1' : '0'));

    showImage(0);
    const startTime = performance.now();

    const step = (now) => {
      const elapsed = now - startTime;
      const raw = Math.min(elapsed / this.houseDuration, 1) * images.length;
      const idx = Math.min(Math.floor(raw), images.length - 1);
      showImage(idx);

      bars.forEach((bar, i) => {
        if (i < idx) bar.style.width = '100%';
        else if (i === idx) bar.style.width = `${(raw - idx) * 100}%`;
        else bar.style.width = '0%';
      });

      if (elapsed < this.houseDuration) {
        this.imageFrame = requestAnimationFrame(step);
      }
    };
    this.imageFrame = requestAnimationFrame(step);
  },

  startHouseTimer() {
    const startTime = performance.now();
    const step = (now) => {
      if (now - startTime < this.houseDuration) {
        this.houseFrame = requestAnimationFrame(step);
      } else {
        this.nextHouse();
      }
    };
    this.houseFrame = requestAnimationFrame(step);
  },

  nextHouse() {
    this.houseIndex = (this.houseIndex + 1) % this.houses.length;
    this.setActiveHouse(this.houseIndex);
    this.startHouseTimer();
  },

  cleanup() {
    if (this.houseFrame) cancelAnimationFrame(this.houseFrame);
    if (this.imageFrame) cancelAnimationFrame(this.imageFrame);
  }
};

export { HouseCardCycle };
export default HouseCardCycle;