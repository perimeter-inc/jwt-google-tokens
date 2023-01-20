defmodule Jwt.Mockcerts.PublicKey do
  def getfor(_id) do
    Jwt.PemParser.extract_exponent_and_modulus_from_pem_cert(certificate())
  end

  def private_key do
    Application.get_env(:jwt, :mock_private_key)
  end

  def certificate do
    Application.get_env(:jwt, :mock_certificate)
  end
end
