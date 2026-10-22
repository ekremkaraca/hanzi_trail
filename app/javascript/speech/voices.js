// Voice discovery for the review "Speak" button.
//
// speechSynthesis.getVoices() is asynchronous: the list is usually
// empty on the first call and fills in later, firing a
// "voiceschanged" event. Treating an empty list as "this browser has
// no Chinese voice" produced false warnings on machines that do have
// one, so discovery resolves only once the browser has reported its
// voices (or a short timeout expires).
//
// The listener is registered with addEventListener instead of
// assigning speechSynthesis.onvoiceschanged: the latter replaces any
// other handler on the shared object and was re-bound on every Turbo
// navigation.

const VOICES_TIMEOUT_MS = 1000;
const VOICES_POLL_MS = 100;

let pending = null;

// Resolve the browser's voice list. The promise is cached — the voice
// list does not change during a visit — and the Speak action re-reads
// the live list at click time anyway.
export function voicesReady() {
  if (pending) return pending;

  pending = new Promise((resolve) => {
    const synthesis = window.speechSynthesis;
    if (!synthesis) {
      resolve([]);
      return;
    }

    let settled = false;
    let poll = null;

    const settle = (voices) => {
      if (settled) return;
      settled = true;
      synthesis.removeEventListener("voiceschanged", onVoicesChanged);
      if (poll) clearInterval(poll);
      resolve(voices);
    };

    const onVoicesChanged = () => {
      const voices = synthesis.getVoices();
      // Some browsers fire the event with an empty list; wait for a
      // populated one unless the timeout expires first.
      if (voices.length > 0) settle(voices);
    };

    synthesis.addEventListener("voiceschanged", onVoicesChanged);
    // Some browsers never fire the event, so poll as well.
    poll = setInterval(onVoicesChanged, VOICES_POLL_MS);
    onVoicesChanged();
    setTimeout(() => settle(synthesis.getVoices()), VOICES_TIMEOUT_MS);
  });

  return pending;
}

// Pick the best available Chinese voice: Mandarin (zh-CN, zh-TW)
// first, then any Chinese locale, then a Chinese voice name.
export function chineseVoice(voices) {
  return (
    voices.find((voice) => voice.lang === "zh-CN") ||
    voices.find((voice) => voice.lang === "zh-TW") ||
    voices.find((voice) => voice.lang?.toLowerCase().startsWith("zh")) ||
    voices.find((voice) => voice.name?.toLowerCase().includes("mandarin")) ||
    voices.find((voice) => voice.name?.toLowerCase().includes("chinese")) ||
    null
  );
}
