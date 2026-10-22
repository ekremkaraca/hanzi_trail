import { Controller } from "@hotwired/stimulus";
import { chineseVoice, voicesReady } from "speech/voices";

// Connects to data-controller="review"
//
// Owns the side-effectful parts of the review card: Web Speech playback and
// keyboard shortcuts (Space, 1–4) that delegate to the rating buttons.
// Pure show/hide state lives in the Alpine `reviewCard()` component; this
// controller stays in sync with it via the `review:visibility-changed` event.
export default class extends Controller {
  static targets = ["character", "speakButton", "voiceHint"];

  connect() {
    this.answerVisible = false;
    // null = not known yet, true = a Chinese voice is available, false =
    // the browser has none. The button stays enabled until we know, so a
    // slow voice list never blocks audio on a machine that has a voice.
    this.voiceAvailable = null;
    this.refreshVoiceState();
  }

  // The browser's voice list fills in asynchronously, so the state is
  // resolved here and applied once it is known.
  async refreshVoiceState() {
    const voices = await voicesReady();

    this.voiceAvailable = Boolean(chineseVoice(voices));
    this.renderVoiceState();
  }

  renderVoiceState() {
    const missing = this.voiceAvailable === false;

    if (this.hasSpeakButtonTarget) {
      this.speakButtonTarget.disabled = missing;
      this.speakButtonTarget.title = missing
        ? "No Mandarin voice is available in this browser."
        : "";
    }

    if (this.hasVoiceHintTarget) {
      this.voiceHintTarget.hidden = !missing;
    }
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

  async speak() {
    if (!("speechSynthesis" in window)) {
      this.voiceAvailable = false;
      this.renderVoiceState();
      return;
    }

    // Voices can finish loading after the page rendered, so re-check
    // the live list before giving up on the cached one.
    let voice = chineseVoice(window.speechSynthesis.getVoices());
    if (!voice) {
      voice = chineseVoice(await voicesReady());
    }

    if (!voice) {
      // No Mandarin voice: reading hanzi with a non-Chinese voice
      // mangles the pronunciation, which is worse than silence for a
      // language app. Disable the button and explain instead.
      this.voiceAvailable = false;
      this.renderVoiceState();
      return;
    }

    this.voiceAvailable = true;
    this.renderVoiceState();

    const utterance = new SpeechSynthesisUtterance(this.speechText());

    utterance.voice = voice;
    utterance.lang = voice.lang;
    utterance.rate = 0.85;
    utterance.pitch = 1;

    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
  }

  speechText() {
    const character = this.characterTarget.textContent.trim();

    // Some Linux voices read Hanzi as "Chinese letter".
    // If that happens on your system, switch this to a data attribute
    // containing pinyin, e.g. data-review-speech-text-value.
    return character;
  }
}
