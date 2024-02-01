defmodule ApitoolkitPhoenix do
  @moduledoc """
  Documentation for `ApitoolkitPhoenix`.
  """
  import Plug.Conn
  require Logger

  defstruct redact_headers: nil,
            redact_request_body: nil,
            redact_response_body: nil,
            project_id: nil,
            debug: nil,
            root_url: nil,
            api_key: nil,
            meta_data: nil,
            debug: false,
            pubsub_conn: nil

  def publishMessage(%{meta_data: meta_data} = %__MODULE__{} = pubsub_client, message) do
    request = %GoogleApi.PubSub.V1.Model.PublishRequest{
      messages: [
        %GoogleApi.PubSub.V1.Model.PubsubMessage{
          data: Base.encode64(message)
        }
      ]
    }

    {:ok, response} =
      GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
        pubsub_client.pubsub_conn,
        Map.get(meta_data, "pubsub_project_id", ""),
        Map.get(meta_data, "topic_id", ""),
        body: request
      )

    IO.inspect("published message #{response.messageIds}")
  end

  def init(config) do
    {:config, config_map} = hd(config)
    root_url = Map.get(config_map, :root_url, "https://app.apitoolkit.io")
    apiKey = Map.get(config_map, :api_key, "")

    if apiKey == "" do
      Logger.error("API Key not found")
    end

    meta_data = get_client_metadata(root_url, apiKey)

    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.PubSub.V1.Connection.new(token.token)

    case Map.get(config_map, :debug, false) do
      true -> nil
      _ -> IO.inspect("apitoolkit: initialized successfully")
    end

    %__MODULE__{
      redact_headers: Map.get(config_map, :redact_headers, []),
      redact_request_body: Map.get(config_map, :redact_request_body, []),
      redact_response_body: Map.get(config_map, :redact_response_body, []),
      project_id: Map.get(meta_data, "project_id", ""),
      root_url: root_url,
      api_key: apiKey,
      meta_data: meta_data,
      debug: Map.get(config_map, :debug, false),
      pubsub_conn: conn
    }
  end

  defp get_client_metadata(root_url, api_key) do
    url = [root_url, "/api/client_metadata"] |> Enum.join()

    resp =
      HTTPoison.get(
        url,
        [
          {"Authorization", "Bearer #{api_key}"},
          {"Accept", "application/json"}
        ],
        []
      )

    case resp do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        bod = Jason.decode!(body)
        bod

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{reason}")
        nil
    end
  end

  def call(conn, default) do
    start_time = System.monotonic_time()

    conn =
      register_before_send(conn, fn conn ->
        payload = build_payload(conn, start_time, default)
        IO.inspect(payload)
        conn
      end)

    assign(conn, :locale, "dd")
  end

  defp build_payload(conn, start_time, config) do
    raw_url = conn.request_path <> conn.query_string
    body = elem(Jason.encode(conn.body_params), 1)
    resp_body = Jason.encode!(conn.resp_body)
    IO.inspect(resp_body)

    %{
      duration: System.monotonic_time() - start_time,
      raw_url: raw_url,
      status_code: conn.status,
      method: conn.method,
      response_headers: redact_headers(conn.resp_headers, Map.get(config, :redact_headers, [])),
      request_headers: redact_headers(conn.req_headers, Map.get(config, :redact_headers, [])),
      host: conn.host,
      path_params: conn.path_params,
      query_params: conn.query_params,
      service_version: nil,
      tags: [],
      proto_major: 1,
      proto_minor: 1,
      project_id: config.project_id,
      errors: [],
      request_body: Base.encode64(body),
      sdk_type: "ElixirPhoenix",
      referer: Map.get(conn, "referer", ""),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  def redact_headers(headers, headers_to_redact) do
    headers_to_redact_lowercase = headers_to_redact |> Enum.map(&String.downcase/1)

    Enum.reduce(headers, %{}, fn {key, value}, acc ->
      lower_key = String.downcase(key)

      is_redact_key =
        Enum.member?(headers_to_redact_lowercase, lower_key) || lower_key == "cookie"

      new_header = if is_redact_key, do: "[CLIENT_REDACTED]", else: value
      Map.put(acc, key, new_header)
    end)
  end
end
