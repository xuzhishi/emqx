defmodule EMQX.Mix.Helpers do
  def read_rebar_config!(filepath) do
    {:ok, config} = read_rebar_config(filepath)
    config
  end

  def read_rebar_config(filepath) do
    filepath
    |> to_charlist()
    |> :file.consult()
  end

  def rebar_to_mix_dep({name, {:git, url, {:tag, tag}}}),
    do: {name, git: to_string(url), tag: to_string(tag)}

  def rebar_to_mix_dep({name, {:git, url, {:ref, ref}}}),
    do: {name, git: to_string(url), ref: to_string(ref)}

  def rebar_to_mix_dep({name, {:git, url, {:branch, branch}}}),
    do: {name, git: to_string(url), branch: to_string(branch)}

  def rebar_to_mix_dep({name, vsn}) when is_list(vsn),
    do: {name, to_string(vsn)}
end
