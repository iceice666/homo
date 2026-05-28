defmodule Harmony.MixProject do
  use Mix.Project

  def project do
    [
      app: :harmony,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Harmony.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end
end
