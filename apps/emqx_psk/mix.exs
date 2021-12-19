defmodule EmqxPSK.MixProject do
  use Mix.Project

  def project do
    [
      app: :emqx_psk,
      version: "5.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      # start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "EMQ X PSK"
    ]
  end

  def application do
    [
      registered: [:emqx_psk_sup],
      mod: {:emqx_psk_app, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:emqx, in_umbrella: true, runtime: false}
    ]
  end
end