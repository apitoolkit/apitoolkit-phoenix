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
    payload = Jason.encode!(message)

    case Map.get(pubsub_client, :debug, false) do
      true -> IO.inspect(message)
      false -> nil
    end

    request = %GoogleApi.PubSub.V1.Model.PublishRequest{
      messages: [
        %GoogleApi.PubSub.V1.Model.PubsubMessage{
          data: Base.encode64(payload)
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

    case Map.get(pubsub_client, :debug, false) do
      true -> IO.inspect("published message #{response.messageIds}")
      false -> nil
    end
  end

  def init(config) do
    {:config, config_map} = hd(config)
    root_url = Map.get(config_map, :root_url, "https://app.apitoolkit.io")
    apiKey = Map.get(config_map, :api_key, "")

    if apiKey == "" do
      Logger.error("API Key not found")
    end

    meta_data = get_client_metadata(root_url, apiKey)

    {:ok, token} =
      Goth.Token.fetch(%{
        source: {:service_account, Map.get(meta_data, "pubsub_push_service_account"), []}
      })

    conn = GoogleApi.PubSub.V1.Connection.new(token.token)

    case Map.get(config_map, :debug, false) do
      true -> IO.inspect("apitoolkit: initialized successfully")
      _ -> nil
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

  def call(conn, config) do
    start_time = System.monotonic_time()
    message_id = UUID.uuid4()
    apitookit = %{message_id: message_id, errors: []}

    conn =
      register_before_send(conn, fn conn ->
        try do
          apitookit = conn.assigns[:apitookit]
          payload = build_payload(conn, start_time, config, message_id, apitookit.errors)
          publishMessage(config, payload)
          conn
        rescue
          _err -> conn
        end

        conn
      end)

    assign(conn, :apitookit, apitookit)
  end

  defp build_payload(conn, start_time, config, message_id, errors) do
    raw_url = conn.request_path <> conn.query_string
    redacted_req_body = redact_fields(conn.body_params, Map.get(config, :redact_request_body))
    router = conn.private.phoenix_router

    body = Jason.encode!(redacted_req_body)

    resp_body =
      try do
        redacted_res_body =
          redact_fields(
            Jason.decode!(IO.iodata_to_binary(conn.resp_body)),
            Map.get(config, :redact_response_body, [])
          )

        Jason.encode!(redacted_res_body)
      rescue
        _err ->
          IO.iodata_to_binary(conn.resp_body)
      end

    route_info =
      Phoenix.Router.route_info(router, conn.method, conn.request_path, conn.host)

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
      service_version: Map.get(config, "service_version", nil),
      tags: Map.get(config, :tags, []),
      url_path: route_info.route,
      proto_major: 1,
      proto_minor: 1,
      project_id: config.project_id,
      errors: errors,
      request_body: Base.encode64(body),
      response_body: Base.encode64(resp_body),
      sdk_type: "ElixirPhoenix",
      msg_id: message_id,
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

  def redact_fields(data, fields_to_redact) do
    try do
      Enum.reduce(fields_to_redact, data, fn field, acc_data ->
        Elixpath.update(acc_data, field, "[CLIENT_REDACTED]")
      end)
    rescue
      _err ->
        data
    end
  end

  def report_error(conn, err) do
    try do
      apitookit = conn.assigns[:apitookit]
      error = build_error(err.kind, err.reason, err.stack)
      errors = Map.get(apitookit, :errors, [])
      apitookit = Map.put(apitookit, :errors, [error | errors])
      assign(conn, :apitookit, apitookit)
    rescue
      err ->
        IO.inspect(err)
        conn
    end
  end

  def report_error(conn, err, stacktrace) do
    try do
      apitookit = conn.assigns[:apitookit]
      error = build_error(:error, err, stacktrace)
      IO.inspect(error)
      errors = Map.get(apitookit, :errors, [])
      apitookit = Map.put(apitookit, :errors, [error | errors])
      assign(conn, :apitookit, apitookit)
    rescue
      _err ->
        conn
    end
  end

  def build_error(kind, reason, stack) do
    iso_string = DateTime.utc_now() |> DateTime.to_iso8601()
    kind = kind
    formatted_error = Exception.format(kind, reason, [])
    formatted_stacktrace = Exception.format(kind, reason, stack)

    %{
      when: iso_string,
      error_type: kind,
      message: formatted_error,
      root_error_type: kind,
      root_error_message: formatted_error,
      stack_trace: formatted_stacktrace
    }
  end
end
