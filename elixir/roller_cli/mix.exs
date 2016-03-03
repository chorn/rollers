defmodule RollerCli.Mixfile do
  use Mix.Project

  def project do
    [app: :roller_cli,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: RollerCli],
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
