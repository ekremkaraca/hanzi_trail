# One line per request, in every environment: method, path, status and
# duration in key=value form instead of Rails' Started/Processing/
# Rendered/Completed block, so a request can be scanned and filtered in
# a single pass. The request-id tag (set in config/application.rb) rides
# on the line, which keeps one request equal to one grep.
#
# The parts lograge drops are added back here:
#
# - It strips the query string from the path and logs no params of its
#   own, so the search text comes back as a whitelisted `query`. No
#   other param is worth a token leaking into the stream.
# - `user` carries the account that made the request, because an error
#   line without an account is an error nobody can reproduce.
# - silence_healthcheck_path stops applying once Rails' request
#   subscriber is detached, so /up is ignored explicitly.
Rails.application.config.lograge.enabled = true
Rails.application.config.lograge.log_level = :info

Rails.application.config.lograge.custom_options = lambda do |event|
  query = event.payload.dig(:params, "query")
  query ? { query: query } : {}
end

Rails.application.config.lograge.custom_payload do
  { user: Current.user&.id }.compact
end

Rails.application.config.lograge.ignore_custom = ->(event) { event.payload[:path] == "/up" }
