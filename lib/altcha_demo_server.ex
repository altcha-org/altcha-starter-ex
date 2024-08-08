defmodule AltchaDemoServer do
  use Plug.Router
  use Plug.ErrorHandler

  import Plug.Conn
  alias Altcha.{ChallengeOptions}

  @altcha_hmac_key System.get_env("ALTCHA_HMAC_KEY") || "default-hmac-key"

  plug CORSPlug,
    origin: ["*"],
    methods: ["GET", "POST", "OPTIONS"],
    headers: ["*"]

  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, """
    ALTCHA server demo endpoints:

    GET /altcha - use this endpoint as challengeurl for the widget
    POST /submit - use this endpoint as the form action
    POST /submit_spam_filter - use this endpoint for form submissions with spam filtering
    """)
  end

  # Fetch challenge
  get "/altcha" do
    options = %ChallengeOptions{
      algorithm: :sha256,
      expires: DateTime.to_unix(DateTime.utc_now(), :second) + 600,
      hmac_key: @altcha_hmac_key,
      max_number: 50_000
    }
    challenge = Altcha.create_challenge(options)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(challenge))
  end

  post "/submit" do
    # Extract the payload from the form body
    payload = conn.body_params["altcha"]

    if payload do
      # Verify the solution
      verified = Altcha.verify_solution(payload, @altcha_hmac_key)

      if verified do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{success: true, data: conn.body_params}))
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid Altcha payload"}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{error: "Altcha payload missing"}))
    end
  end

  # Handle submissions with spam filter
  post "/submit_spam_filter" do
    # Extract the payload from the form body
    payload = conn.body_params["altcha"]

    if payload do
      # Verify the payload
      {verified, verification_data} = Altcha.verify_server_signature(payload, @altcha_hmac_key)

      if verified and verification_data do
        # Verify the fields signature
        fields_verified = Altcha.verify_fields_hash(conn.body_params, verification_data.fields, verification_data.fields_hash, :sha256)

        if fields_verified do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{success: true, form_data: conn.body_params, verification_data: verification_data}))
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{error: "Fields hash does not match"}))
        end

      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid Altcha payload"}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{error: "Altcha payload missing"}))
    end
  end

  # Handle errors
  def handle_errors(conn, %{kind: _kind, reason: _reason}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(%{error: "Internal Server Error"}))
  end
end

# Start the server
defmodule AltchaDemoServer.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: AltchaDemoServer,
        options: [port: String.to_integer(System.get_env("PORT") || "3000")]
      )
    ]

    opts = [strategy: :one_for_one, name: AltchaDemoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
