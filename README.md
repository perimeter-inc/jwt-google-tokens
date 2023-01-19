
# JWT verifier for Google tokens

Elixir library that verifies Google generated JWT tokens (such as those returned by Firebase authentication) and returns the claims data.

The intended use case is to validate signed tokens retrieved by a mobile app using [Firebase Authentication](https://firebase.google.com/docs/auth/), where the app talks directly with the Google Authentication service and retrieves an authentication token (a Json Web Token) that can be later sent to a server for verification or by web apps that use the Firebase [JavaScript API](https://firebase.google.com/docs/auth/web/google-signin).  

JWT tokens are also returned by other Google authentication services and this library could be used to verify them too.

## Usage

```
iex > {:ok, claims} = Jwt.verify token
```

If you just want to display the contents (claims) of a token quickly you can just run:
```
iex > Jwt.Display.display token
```
No validation is performed in the token in that case.

## Installation

The package can be installed as follows (will try to make it available in Hex in a future version):

  1. Add `jwt` to your list of dependencies in `mix.exs`:

```
def deps do
  [{:jwt, git: "https://github.com/amezcua/jwt-google-tokens.git", branch: "master"}]
end
```

  2. Ensure `jwt` is started before your application:

```
def application do
  [applications: [:jwt]]
end
```

or, depending on your version of Elixir

```
def application do
    [ extra_applications: [:jwt] ]
end
```

## Plugs

Two plugs are provided:

```
- Jwt.Plugs.VerifyAuthorizationHeader
```

The plug looks at the HTTP Authorization header to see if it includes a value with the format

```
Authorization: Bearer [JWT]
```

where *[JWT]* is a JWT token. If it is there the library will attempt to verify the signature and attach the claims to the *Plug.Conn* object. The claims can then be accessed with the *:jwtclaims* atom:

```
claims = conn.assigns[:jwtclaims]
name = claims["name"]
```

If the token is invalid, the plug with directly return a 401 response to the client.

The tokens expiration timestamp are also checked to verify that they have not expired. Expired tokens (within a 5 minute time difference) are rejected.

```
- Jwt.Plugs.FilterClaims
```

This plug allows you to accept or deny a request based on the contents of the claims. Please take a look at the tests to see the different options you have to filter a request based on the token content.

## Testing

For testing purposes, the package can be configured to accept a given certificate and private key to mock out the Google's, like so:

```elixir
config :jwt,
  googlecerts: Jwt.Mockcerts.PublicKey,
  mock_certificate: """
  -----BEGIN CERTIFICATE-----
  certificate contents
  -----END CERTIFICATE-----
  """,
  mock_private_key: """
  -----BEGIN PRIVATE KEY-----
  private key contents
  -----END PRIVATE KEY-----
  """
```

Then, during tests setup, simply generate a JWT token signed by this private key, which can then be verified by `Jwt`.

One example using [JSON Web Token library](https://github.com/garyf/json_web_token_ex):

```elixir
  setup do
    claims = %{user_id: user_id, exp: exp}
    private_key = JsonWebToken.Algorithm.RsaUtil.private_key(Jwt.Mockcerts.PublicKey.private_key())
    {:ok, token} = JsonWebToken.sign(claims, %{alg: "RS256", key: private_key})

    {:ok, %{token: token}}
  end

  test "my test" do
    default_options = [
      Jwt.Plugs.Verification.default_options().ignore_token_expiration,
      Jwt.Plugs.Verification.default_options().time_window
    ]

    assert {:ok, claims} = Jwt.Plugs.Verification.verify_token(token, default_options)
  end
```

## License

[Apache v2.0](https://opensource.org/licenses/Apache-2.0)