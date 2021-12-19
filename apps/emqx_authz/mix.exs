defmodule EMQXAuthz.MixProject do
  use Mix.Project
  Code.require_file("../../lib/emqx/mix/common.ex")

  @app :emqx_authz

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      # start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: EMQX.Mix.Common.from_erl!(@app, :mod),
      applications: EMQX.Mix.Common.from_erl!(@app, :applications),
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:emqx_connector, in_umbrella: true, runtime: false}
    ]
  end
end
