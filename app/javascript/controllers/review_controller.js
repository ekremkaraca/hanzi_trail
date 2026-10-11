import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="review"
//
// Owns the side-effectful parts of the review card: Web Speech playback and
// keyboard shortcuts (Space, 1–4) that delegate to the rating buttons.
// Pure show/hide state lives in the Alpine `reviewCard()` component; this
// controller stays in sync with it via the `review:visibility-changed` event.
export default class extends Controller {
  static targets = ["character"];

  connect() {
    this.answerVisible = false;
    this.loadVoices();
  }

  handleVisibilityChanged(event) {
    this.answerVisible = !!event.detail?.visible;
  }

  handleKeydown(event) {
    // Space natively activates focused buttons/links and toggles checkboxes,
    // so never hijack it while an interactive control has focus.
    if (event.code === "Space") {
      if (this.isInteractive(event.target)) return;

      event.preventDefault();
      window.dispatchEvent(new Event("review:toggle"));
      return;
    }

    // Digit keys are inert on buttons and checkboxes; only suppress them
    // for text entry so rating with 1-4 still works right after clicking
    // "Show answer" (focus stays on that button).
    if (this.isTextEntry(event.target)) return;

    if (!this.answerVisible) return;

    const button = Array.from(
      this.element.querySelectorAll("[data-review-rating]"),
    ).find((element) => element.dataset.reviewRating === event.key);

    if (button) {
      event.preventDefault();
      button.click();
    }
  }

  isInteractive(target) {
    if (!(target instanceof HTMLElement)) return false;

    return (
      target.isContentEditable ||
      ["INPUT", "TEXTAREA", "SELECT", "BUTTON", "A"].includes(target.tagName)
    );
  }

  isTextEntry(target) {
    if (!(target instanceof HTMLElement)) return false;

    if (target.isContentEditable) return true;
    if (["TEXTAREA", "SELECT"].includes(target.tagName)) return true;

    return (
      target.tagName === "INPUT" &&
      !["checkbox", "radio", "button", "submit"].includes(target.type)
    );
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
}
