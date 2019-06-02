defmodule PlotterTest do
  require Logger
  use ExUnit.Case
  alias Plotter.Axis
  alias Plotter.ViewRange

  doctest Plotter

  test "data plots" do

    xdata = 1..4 |> Enum.map(& &1 )
    ydata = xdata |> Enum.map(& :math.sin(&1/10.0) )


    xlims = Plotter.NumberUnits.range_from(xdata) |> Plotter.ViewRange.new(:horiz)
    xaxis = %Axis{limits: xlims}
    # Logger.warn("xlims: #{inspect xlims}")
    # Logger.warn("xaxis: #{inspect xaxis}")

    ylims = Plotter.NumberUnits.range_from(ydata) |> Plotter.ViewRange.new(:vert)
    yaxis = %Axis{limits: ylims}
    # Logger.warn("ylims: #{inspect ylims}")
    # Logger.warn("yaxis: #{inspect yaxis}")

    {xrng, yrng} = Plotter.plot_data({xdata, ydata}, xaxis, yaxis)
    # Logger.warn("xrng: #{inspect xrng |> Enum.to_list()}")
    # Logger.warn("yrng: #{inspect yrng |> Enum.to_list()}")

    xs = [{1, 0.1}, {2, 0.3666666666666667}, {3, 0.6333333333333333}, {4, 0.9}]
    assert xs == Enum.to_list(xrng)
    ys = [{0.09983341664682815, 0.1}, {0.19866933079506122, 0.37304159958561867}, {0.29552020666133955, 0.6405993825604989}, {0.3894183423086505, 0.9}]
    assert ys == Enum.to_list(yrng)
  end

  test "plot limits" do

    xdata = 1..4 |> Enum.map(& &1 )
    ydata = xdata |> Enum.map(& :math.sin(&1/10.0) )

    xlims = Plotter.NumberUnits.range_from(xdata) |> Plotter.ViewRange.new()
    xaxis = %Axis{limits: xlims}

    ylims = Plotter.NumberUnits.range_from(ydata) |> Plotter.ViewRange.new()
    yaxis = %Axis{limits: ylims}

    {xrng, yrng} = Plotter.limits([{xdata, ydata}])

    assert %ViewRange{start: 1, stop: 4} == xrng
    assert %ViewRange{start: 0.09983341664682815, stop: 0.3894183423086505} == yrng
  end

  test "simple plot" do
    xdata = 1..4 |> Enum.map(& &1 )
    ydata = xdata |> Enum.map(& :math.sin(&1/10.0) )

    plt = Plotter.plot([{xdata, ydata}])
    Logger.warn("plotter cfg: #{inspect plt }")
  end

  test "nil plot" do
    xdata = []
    ydata = []

    plt = Plotter.plot([{xdata, ydata}])
    Logger.warn("plotter cfg: #{inspect plt }")
  end

  # test "nil date plot" do
  #   xdata = []
  #   ydata = []

  #   plt = Plotter.plot([{xdata, ydata}], xkind: :datetime)
  #   Logger.warn("plotter cfg: #{inspect plt }")
  # end

  test "date plot" do
    xdata = [0.0, 2.0, 3.0, 4.0]
    ydata = [0.1, 0.25, 0.15, 0.1]

    plt = Plotter.plot([{xdata, ydata}], xkind: :numeric)
    # Logger.warn("plotter cfg: #{inspect plt }")

    # for xt <- plt.xticks do
    #   Logger.info("xtick: #{inspect xt}")
    # end

    # for yt <- plt.yticks do
    #   Logger.info("xtick: #{inspect yt}")
    # end

    # for data <- plt.datasets do
    #   for {x,y} <- data do
    #     Logger.info("data: #{inspect {x,y}}")
    #   end
    # end

  end

  test "svg plot" do
    xdata = [0.0, 2.0, 3.0, 4.0]
    ydata = [0.1, 0.25, 0.15, 0.1]

    plt = Plotter.plot([{xdata, ydata}], xkind: :numeric)
    Logger.error("svg plotter cfg: #{inspect plt, pretty: true }")

    svg_str = Plotter.Output.Svg.generate(plt)

    Logger.warn("SVG: \n#{svg_str}")

    html_str = """
    <html>
    <head>
      <style>
        .graph .labels .x-labels {
          text-anchor: middle;
        }

        .graph .labels .y-labels {
          text-anchor: end;
        }

        .graph {
          height: 500px;
          width: 800px;
        }

        .graph .grid {
          stroke: #ccc;
          stroke-dasharray: 0;
          stroke-width: 0.01;
        }

        .labels {
          font-size: 13px;
        }

        .label-title {
          font-weight: bold;
          text-transform: uppercase;
          font-size: 12px;
          fill: black;
        }

        .data {
          fill: red;
          stroke-width: 0.01;
        }
      </style>
    </head>
    <body>
      #{svg_str}
      <h2>Test</h2>
      <svg version="1.2" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="graph" aria-labelledby="title" role="img">
        <title id="title">A line chart showing some information</title>
        <g class="grid x-grid" id="xGrid">
          <line x1="90" x2="90" y1="5" y2="371"></line>
        </g>
        <g class="grid y-grid" id="yGrid">
          <line x1="90" x2="705" y1="370" y2="370"></line>
        </g>
        <g class="labels x-labels">
          <text x="100" y="400">2008</text>
          <text x="246" y="400">2009</text>
          <text x="392" y="400">2010</text>
          <text x="538" y="400">2011</text>
          <text x="684" y="400">2012</text>
          <text x="400" y="440" class="label-title">Year</text>
        </g>
        <g class="labels y-labels">
          <text x="80" y="15">15</text>
          <text x="80" y="131">10</text>
          <text x="80" y="248">5</text>
          <text x="80" y="373">0</text>
          <text x="50" y="200" class="label-title">Price</text>
        </g>
      </svg>
    </body>
    </html>
    """
    File.write!("output.html", html_str)
  end

end
