defmodule EMQX.Mix.Common do
  def erl_apps(app) do
    from_erl!(app, :applications)
  end

  def from_erl!(app, key) do
    path = Path.join("src", "#{app}.app.src")
    {:ok, [{:application, ^app, props}]} = :file.consult(path)
    Keyword.fetch!(props, key)
  end
end
