defmodule EMQXModules.MixProject do
  use Mix.Project
  Code.require_file("../../lib/emqx/mix/common.ex")

  def project do
    [
      app: :emqx_modules,
      version: "4.3.2",
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
      registered: [:emqx_mod_sup],
      mod: {:emqx_modules_app, []},
      applications: EMQX.Mix.Common.from_erl!(:emqx_modules, :applications),
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:emqx, in_umbrella: true, runtime: false},
    ]
  end
end
