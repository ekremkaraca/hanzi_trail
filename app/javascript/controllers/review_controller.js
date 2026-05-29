import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "character", "showButton"];

  showAnswer() {
    this.answerTarget.hidden = false;
    this.element.classList.add("is-answer-visible");

    if (this.hasShowButtonTarget) {
      this.showButtonTarget.textContent = "Hide answer";
    }
  }

  hideAnswer() {
    this.answerTarget.hidden = true;
    this.element.classList.remove("is-answer-visible");

    if (this.hasShowButtonTarget) {
      this.showButtonTarget.textContent = "Show answer";
    }
  }

  toggleAnswer() {
    this.answerVisible = !this.answerVisible;

    this.answerTarget.hidden = !this.answerVisible;
    this.showButtonTarget.textContent = this.answerVisible
      ? "Hide answer"
      : "Show answer";
  }

  handleKeydown(event) {
    if (event.code === "Space") {
      event.preventDefault();
      this.toggleAnswer();
      return;
    }

    if (!this.answerVisible) return;

    const button = Array.from(
      this.element.querySelectorAll("[data-review-rating]"),
    ).find((element) => element.dataset.reviewRating === event.key);

    if (button) {
      event.preventDefault();
      button.click();
    }
  }

  speak() {
    if (!("speechSynthesis" in window)) {
      console.warn("Speech synthesis is not supported in this browser.");
      return;
    }

    const text = this.speechText();
    const utterance = new SpeechSynthesisUtterance(text);

    utterance.lang = "zh-CN";
    utterance.rate = 0.85;
    utterance.pitch = 1;

    const voice = this.findChineseVoice();

    if (voice) {
      utterance.voice = voice;
    } else {
      console.warn("No Mandarin/Chinese voice found. Using default voice.");
    }

    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
  }

  loadVoices() {
    this.voices = window.speechSynthesis?.getVoices() || [];

    if ("speechSynthesis" in window) {
      window.speechSynthesis.onvoiceschanged = () => {
        this.voices = window.speechSynthesis.getVoices();
      };
    }
  }

  findChineseVoice() {
    const voices =
      this.voices.length > 0 ? this.voices : window.speechSynthesis.getVoices();

    return (
      voices.find((voice) => voice.lang === "zh-CN") ||
      voices.find((voice) => voice.lang?.toLowerCase().startsWith("zh")) ||
      voices.find((voice) => voice.name.toLowerCase().includes("mandarin")) ||
      voices.find((voice) => voice.name.toLowerCase().includes("chinese"))
    );
  }

  speechText() {
    const character = this.characterTarget.textContent.trim();

    // Some Linux voices read Hanzi as "Chinese letter".
    // If that happens on your system, switch this to a data attribute
    // containing pinyin, e.g. data-review-speech-text-value.
    return character;
  }

  connect() {
    this.answerVisible = false;
    this.loadVoices();
  }

  disconnect() {}
}
