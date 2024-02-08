defprotocol Elixpath.Update do
  @moduledoc """
  Used for querying each data type.
  """

  @fallback_to_any true
  require Elixpath.Tag, as: Tag

  @doc """
  Fetches all children that matches `key` from `data`.

  `key` can be `Elixpath.Tag.wildcard()` (i.e. `#{inspect(Elixpath.Tag.wildcard())}`), which stands for "all the children"
  """
  @spec update(data :: term, key :: Tag.wildcard() | term, update_val :: any) ::
          term
  def update(data, key, opts)
end

defimpl Elixpath.Update, for: Any do
  @spec update(any, any, any) :: any
  def update(data, _key, _opts), do: data
end

defimpl Elixpath.Update, for: Map do
  require Elixpath.Tag, as: Tag

  @spec update(map, any, any) :: term
  def update(data, Tag.wildcard(), updated_val) do
    data
    |> Enum.map(fn {key, _value} -> {key, updated_val} end)
    |> Map.new()
  end

  def update(data, key, updated_val) do
    case Map.fetch(data, key) do
      {:ok, _} ->
        updated_data = Map.put(data, key, updated_val)
        updated_data

      :error ->
        data
    end
  end
end

defimpl Elixpath.Update, for: List do
  require Elixpath.Tag

  @spec update(list, any, any, boolean) :: any
  def update(data, Elixpath.Tag.wildcard(), update_val, is_end) do
    if Keyword.keyword?(data) do
      values = Keyword.values(data)

      if is_end do
        Enum.map(values, fn _v -> update_val end)
      else
        values
      end
    else
      data
    end
  end

  def update(data, index, update_val) when is_integer(index) and index < 0 do
    new_list = List.update_at(data, length(data) + index, fn _ -> update_val end)
    new_list
  end

  def update(data, index, update_val) when is_integer(index) and index >= 0 do
    case Enum.at(data, index, _default = :elixpath_not_found) do
      :elixpath_not_found ->
        data

      _ ->
        new_list = List.update_at(data, index, fn _ -> update_val end)
        new_list
    end
  end

  def update(data, key, update_val) do
    updated_list =
      data
      |> Enum.map(fn
        {^key, _value} -> {key, update_val}
        v -> v
      end)

    updated_list
  end
end
