class AudiosController < ApplicationController
  # Audio is anonymous-viewable, matching review access.
  allow_unauthenticated_access

  def show
    # Key contains slashes ("words/12-xiaoxiao.mp3") — served whole.
    bytes = AudioStorage.find_bytes(params[:key])

    # Immutable per key: a voice re-render gets a fresh key, so browsers
    # may cache forever and never see a stale word. (send_data has no
    # cache_control option — set it before serving.)
    response.set_header("Cache-Control", "public, max-age=31536000, immutable")
    send_data bytes, type: "audio/mpeg", filename: File.basename(params[:key])
  end
end
