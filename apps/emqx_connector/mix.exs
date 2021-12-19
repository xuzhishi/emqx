defmodule EMQXConnector.MixProject do
  use Mix.Project
  Code.require_file("../../lib/emqx/mix/common.ex")

  def project do
    [
      app: :emqx_connector,
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
      mod: {:emqx_connector_app, []},
      applications: EMQX.Mix.Common.from_erl!(:emqx_connector, :applications),
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:emqx_resource, in_umbrella: true, runtime: false},
      {:epgsql, github: "epgsql/epgsql", tag: "4.4.0"},
      {:mysql, github: "emqx/mysql-otp", tag: "1.7.1"},
      {:emqtt, github: "emqx/emqtt", tag: "1.4.3"},
      {:eredis_cluster, github: "emqx/eredis_cluster", tag: "0.6.7"},
      {:mongodb, github: "emqx/mongodb-erlang", tag: "v3.0.10"},
      # {:ecpool, github: "emqx/ecpool", tag: "0.5.1"},
      # {:emqtt, github: "emqx/emqtt", tag: "1.4.3"}
    ]
  end
end
