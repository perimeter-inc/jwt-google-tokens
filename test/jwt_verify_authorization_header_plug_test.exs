defmodule JwtVerifyAuthorizationHeaderPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Jwt.TimeUtils.Mock, as: TimeUtils

  @plug Jwt.Plugs.VerifyAuthorizationHeader

  @opts []

  @test_header "eyJhbGciOiJSUzI1NiIsImtpZCI6IjEwZWZiZjlmOWEzZThlYzVlN2RmYTc5NjFkNzFlMmU0YmZkYTI0MzUifQ"
  @test_claims "eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhdWQiOiIzNDczODQ1NjIxMTMtcmRtNnNsZG0xbWIzOGs0dW1yY28zcDhsN3I1aGcwazUuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMTAzNjE0MDAyNDQ4NzEyMjU0MTQiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXpwIjoiMzQ3Mzg0NTYyMTEzLXIyOHBqZDB1Yzlwb2Y1Y20xcDBubmwyNXM5N2o4dXFwLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiaGQiOiJieXRlYWJ5dGUubmV0IiwiZW1haWwiOiJhbGVqYW5kcm8ubWV6Y3VhQGJ5dGVhYnl0ZS5uZXQiLCJpYXQiOjE0NzMyMjU4NjQsImV4cCI6MTQ3MzIyOTQ2NCwibmFtZSI6IkFsZWphbmRybyBNZXpjdWEiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tLy1mSUpUN0cydVozRS9BQUFBQUFBQUFBSS9BQUFBQUFBQUFRWS9KdkNWbUZIWG5yOC9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiQWxlamFuZHJvIiwiZmFtaWx5X25hbWUiOiJNZXpjdWEiLCJsb2NhbGUiOiJlbiJ9"
  @test_signature "Kc90u_gtZyhq6glw6UoYQSInZx9r16uqrRO7g50x17JWH7VkyAZrh3sfjdBYpGtDNJjDRBKSxuinpDjpyfiCp3-XAqqOUWqziyYvkV4-CdQvNhcnUQFXjjx_CzNiiEi5PRPCHhX4ajidet1NH4Me02S17gwOZiaZfed1BMWQuQ_7Hf2RsX5FID1xqOpcaaouMFcrqQFmdBIbcstHamWxs9D83c4JpOsioNOMb6-LBinzOg7qdxr1D4NvHD6VSXBTbyXiOBjK2elLU1iCz_Hz_BH-R1IYCdTRr5PczRWdSCgoTdZ7ds1nTTglfuXlGNbaEhhzsFxX8OCR4uNK6vbWXQ"
  # Expiration timestamp for the token avobe
  @test_token_exp_value 1_473_229_464
  @ten_minutes 10 * 60
  @four_minutes 4 * 60

  test "Missing authorization header returns 401" do
    TimeUtils.set_time_for_tests()
    conn = conn(:get, "/protected")

    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "Empty authorization header returns 401" do
    TimeUtils.set_time_for_tests()
    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", "")

    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "Invalid token in authorization header returns 401" do
    TimeUtils.set_time_for_tests()
    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", "token")

    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "Valid token is allowed" do
    TimeUtils.set_time_for_tests()
    valid_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> valid_token

    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", auth_header)
    conn = @plug.call(conn, @plug.init([true, 5 * 60]))

    claims = conn.assigns[:jwtclaims]
    assert claims != nil
    assert claims["name"] == "Alejandro Mezcua"
  end

  test "Expired token is rejected by default" do
    TimeUtils.set_time_for_tests()
    expired_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> expired_token

    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", auth_header)
    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "Token expiration allowed below but outside time window" do
    TimeUtils.set_time_for_tests(@test_token_exp_value - @ten_minutes)
    expired_in_window_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> expired_in_window_token

    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", auth_header)
    conn = @plug.call(conn, @plug.init(@opts))

    claims = conn.assigns[:jwtclaims]
    assert claims != nil
    assert claims["name"] == "Alejandro Mezcua"
  end

  test "Token expiration not allowed below but within time window" do
    TimeUtils.set_time_for_tests(@test_token_exp_value - @four_minutes)
    expired_in_window_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> expired_in_window_token

    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", auth_header)
    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "Token expiration not allowed above expiration time" do
    TimeUtils.set_time_for_tests(@test_token_exp_value + 1)
    expired_in_window_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> expired_in_window_token

    conn = conn(:get, "/protected")
    conn = put_req_header(conn, "authorization", auth_header)
    conn = @plug.call(conn, @plug.init(@opts))

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body == ""
  end

  test "supports token header in query params" do
    TimeUtils.set_time_for_tests()
    valid_token = @test_header <> "." <> @test_claims <> "." <> @test_signature
    auth_header = "Bearer " <> valid_token

    conn = conn(:get, "/protected?Authorization=#{auth_header}")
    conn = @plug.call(conn, @plug.init([true, 5 * 60]))

    claims = conn.assigns[:jwtclaims]
  end
end
