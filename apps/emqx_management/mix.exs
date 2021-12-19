defmodule EMQXManagement.MixProject do
  use Mix.Project
  Code.require_file("../../lib/emqx/mix/common.ex")

  def project do
    [
      app: :emqx_management,
      version: "4.4.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      # start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "EMQ X Management API and CLI"
    ]
  end

  def application do
    [
      registered: [:emqx_management_sup],
      mod: {:emqx_mgmt_app, []},
      applications: EMQX.Mix.Common.from_erl!(:emqx_management, :applications),
      extra_applications: [:logger, :syntax_tools]
    ]
  end

  defp deps do
    [
      {:emqx, in_umbrella: true, runtime: false},
      # {:emqx_rule_engine, in_umbrella: true},
      # {:ekka, github: "emqx/ekka", tag: "0.11.1", runtime: false},
      # {:emqx_http_lib, github: "emqx/emqx_http_lib", tag: "0.2.1"},
      {:minirest, github: "emqx/minirest", tag: "1.2.7"},
    ]
  end
end