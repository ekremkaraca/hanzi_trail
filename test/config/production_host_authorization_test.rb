# Regression test: production must reject a hostile Host header. An empty
# config.hosts silently allows every host (middleware short-circuit), so this
# boots the real production config in a subprocess and asserts the behavior.
# Booting needs no DB because only config values are inspected.
require "test_helper"

class ProductionHostAuthorizationTest < ActiveSupport::TestCase
  SCRIPT = <<~RUBY
    hosts = Rails.application.config.hosts
    perm  = ActionDispatch::HostAuthorization::Permissions.new(hosts)
    configured = ENV.fetch("APP_HOST", "hanzitrail.fly.dev")
    puts "configured=\#{perm.allows?(configured)}"
    puts "hostile=\#{perm.allows?("evil.example.com")}"
    inner = ->(_env) { [ 200, {}, [ "ok" ] ] }
    mw = ActionDispatch::HostAuthorization.new(
      inner, hosts, exclude: Rails.application.config.host_authorization[:exclude]
    )
    env = Rack::MockRequest.env_for("https://x/").merge("HTTP_HOST" => configured)
    puts "real_host_status=\#{mw.call(env).first}"
    env2 = Rack::MockRequest.env_for("https://x/").merge("HTTP_HOST" => "evil.example.com")
    puts "hostile_status=\#{mw.call(env2).first}"
  RUBY

  test "production blocks hostile hosts and allows the configured host" do
    out = IO.popen(
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1" },
      [ Rails.root.join("bin/rails").to_s, "runner", "-" ],
      "r+", err: File::NULL
    ) { |io| io.write(SCRIPT); io.close_write; io.read }

    assert_includes out, "configured=true",
      "the app's own host must be allowed"
    assert_includes out, "hostile=false",
      "a hostile Host header must be rejected (config.hosts empty allows all)"
    assert_includes out, "real_host_status=200"
    assert_includes out, "hostile_status=403"
  end
end
