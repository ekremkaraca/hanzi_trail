require "test_helper"

class QueryParamTest < ActiveSupport::TestCase
  test "passes a normal string through" do
    assert_equal "hsk", QueryParam.scalar("hsk")
  end

  test "returns nil for nil" do
    assert_nil QueryParam.scalar(nil)
  end

  test "treats an Array as absent instead of raising downstream" do
    assert_nil QueryParam.scalar([ "a" ])
  end

  test "treats a nested Hash as absent" do
    assert_nil QueryParam.scalar({ "a" => "b" })
  end

  test "strips NUL bytes that PostgreSQL rejects" do
    assert_equal "abc", QueryParam.scalar("a\u0000bc")
  end

  test "a NUL-only value becomes blank/absent" do
    assert_nil QueryParam.scalar("\u0000")
  end

  test "blank string becomes absent" do
    assert_nil QueryParam.scalar("")
  end

  test "does not coerce other types via to_s" do
    assert_nil QueryParam.scalar(123)
    assert_nil QueryParam.scalar(:sym)
  end
end
