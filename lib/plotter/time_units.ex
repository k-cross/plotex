defmodule Plotter.TimeUnits do
  require Logger

  @time_basis [
    full_year: 31_536_000,
    full_month: 2_592_000,
    full_week: 604_800,
    full_day: 86_400,
    half_day: 43_200,
    quarter_day: 21_600,
    eigth_day: 10_800,
    full_hour: 3_600,
    half_hour: 1_800,
    quarter_hour: 900,
    minute: 60,
    half_minute: 30,
    quarter_minute: 15,
    second: 1,
    millisecond: 1.0e-3,
    microsecond: 1.0e-6
  ]

  @doc """
  Get units for a given date range, using the number of ticks.

  """
  @spec units_for(DateTime.t(), DateTime.t(), keyword()) :: {integer(), atom(), integer()}
  def units_for(dt_a, dt_b, opts \\ []) do
    DateTime.diff(dt_a, dt_b)
    |> abs()
    |> optimize_units(opts)
  end

  @spec date_range_from(Enumerable.t()) :: {DateTime.t(), DateTime.t()}
  def date_range_from(data) do
    a = Enum.at(data, 0)
    b = Enum.at(data, -1)

    unless DateTime.compare(a, b) == :lt do
      {a, b}
    else
      {b, a}
    end
  end

  def optimize_units(diff_seconds, opts \\ []) do
    count = Keyword.get(opts, :ticks, 10)
    delta = diff_seconds / count

    idx =
      @time_basis
      |> Enum.find_index(fn {_time_unit, dt_val} ->
        delta >= dt_val
      end)

    {basis_name, basis_val} = @time_basis |> Enum.at(idx |> max(0) |> min(Enum.count(@time_basis) - 1))
    {diff_seconds, basis_name, basis_val}
  end

  def time_units() do
    @time_basis
  end

  def next_smaller_unit({_name, amount}) do
    optimize_units(amount - 1.0) |> elem(1)
  end

  def time_scale(data, opts \\ []) do
    {dt_a, dt_b} = date_range_from(data)
    time_scale(dt_a, dt_b, opts)
  end

  def time_scale(dt_a, dt_b, opts) do
    {diff_seconds, unit_name, unit_val} = units_for(dt_a, dt_b, opts)
    Logger.warn("time_name: #{inspect(unit_name)}")
    Logger.warn("time_val: #{inspect(unit_val)}")
    dt_start = clone(dt_a, unit_name)

    basis_count = diff_seconds / unit_val
    stride = if opts[:ticks] do
                round(basis_count / opts[:ticks])
              else
                round(basis_count / 10)
              end
    Logger.warn("time_stride: #{inspect(stride)}")


    0..1_000_000_000
    |> Stream.map(fn i ->
      # Logger.warn("#{inspect(dt_start)}")
      # Logger.warn("#{inspect({i, unit_val, i * unit_val})}")
      DateTime.add(dt_start, i * unit_val, :second)
    end)
    |> Stream.take_every(stride)
    |> Stream.take_while(fn dt -> DateTime.compare(dt, dt_b) == :lt end)
  end

  @spec gets(map(), {atom(), integer()}, atom()) :: integer()
  defp gets(dt, {_base_unit, base_number}, field) do
    {_field_unit, field_val} = basis_unit(field)

    cond do
      base_number >= field_val ->
        dt[field]

      true ->
        0
    end
  end

  def clone(%DateTime{} = dt, unit) do
    bu = basis_unit(unit)
    dt = dt |> Map.from_struct()

    %DateTime{
      day: gets(dt, bu, :day),
      hour: gets(dt, bu, :hour),
      minute: gets(dt, bu, :minute),
      month: gets(dt, bu, :month),
      second: gets(dt, bu, :second),
      microsecond: {gets(dt, bu, :microsecond), 6},
      calendar: dt.calendar,
      std_offset: dt.std_offset,
      time_zone: dt.time_zone,
      utc_offset: dt.utc_offset,
      year: dt.year,
      zone_abbr: dt.zone_abbr
    }
  end

  @spec basis_unit(atom()) ::
          {:day, 1}
          | {:hour, 2}
          | {:minute, 3}
          | {:second, 4}
          | {:microsecond, 5}
  def basis_unit(unit_name) do
    case unit_name do
      n when n in [:full_year, :year] ->
        {:year, 1}

      n when n in [:full_month, :month] ->
        {:month, 2}

      n when n in [:full_week, :week] ->
        {:week, 3}

      n when n in [:full_day, :decade] ->
        {:day, 4}

      n when n in [:full_day, :year] ->
        {:day, 5}

      n when n in [:full_day, :month] ->
        {:day, 6}

      n when n in [:full_day, :day] ->
        {:day, 7}

      n when n in [:half_day, :quarter_day, :eigth_day, :full_hour, :hour] ->
        {:hour, 8}

      n when n in [:half_hour, :quarter_hour, :minute] ->
        {:minute, 9}

      n when n in [:half_minute, :quarter_minute, :second] ->
        {:second, 10}

      n when n in [:millisecond, :microsecond] ->
        {:microsecond, 11}
    end
  end
end
