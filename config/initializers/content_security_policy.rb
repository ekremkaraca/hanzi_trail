# Application-wide Content Security Policy.
#
# The app is fully same-origin: vendored Pure CSS, Propshaft-served JS
# (importmap), Alpine + Stimulus, Turbo. No third-party scripts, fonts,
# or images, so the policy stays tight:
#
# - script-src 'self' 'unsafe-eval': Alpine compiles x-data/x-show
#   expressions with new Function, which requires 'unsafe-eval'. Inline
#   script tags (the importmap JSON and the `import "application"`
#   bootstrap) are covered by the per-request nonce below, not by
#   'unsafe-inline'. importmap-rails attaches the nonce automatically.
# - style-src 'self': the two former inline style attributes were moved
#   to .gap-lg / .scroll-x utilities so no style exceptions are needed.
# - img_src also allows data: for the brand icon and any inline SVG
#   data URIs.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.font_src    :self
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self, :unsafe_eval
    policy.style_src   :self
    policy.connect_src :self
    policy.form_action :self
  end

  # Per-request random nonce. The stock session-id generator from the Rails
  # template is unusable here: the cookie session is lazy and session.id is
  # "" for visitors who never touched a review action, producing an empty
  # nonce that leaves Turbo's injected progress-bar <style> blocked.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  # style-src must be in the nonce list: Turbo's progress bar injects a
  # <style> element and stamps it with the nonce read from the
  # <meta name="csp-nonce"> tag. With only script-src listed, Rails leaves
  # that meta empty and the injected stylesheet is blocked (prod console
  # error at turbo.es2017-esm.js createStylesheetElement).
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
