defmodule Mix.Tasks.Compile.RenderConfig do
  use Mix.Task.Compiler

  def run(_args) do
    cmd = "./rebar3"
    args = ["deps"]
    System.cmd(cmd, args, env: [{"DEBUG", "1"}], into: IO.stream(:stdio, :line))
  end
end
