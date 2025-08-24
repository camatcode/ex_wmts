defmodule ExWMTS.Doc do
  @moduledoc false

  def mod_doc(description, opts \\ []) do
    description = render_description(description)
    example = render_example(opts[:example])
    related = render_related(opts[:related])
    warning = render_warning(opts[:warning])
    ogc_common = render_ogc_common(opts[:ogc_common])

    """
    #{description}

    #{warning}

    #{ogc_common}

    #{example}

    #{resources()}

    #{related}

    """
  end

  def type_doc(description, opts \\ []) do
    description = render_description(description)
    keys = render_keys(opts[:keys])
    example = render_example(opts[:example])
    related = render_related(opts[:related])
    warning = render_warning(opts[:warning])

    """
    #{description}

    #{warning}

    #{keys}

    #{example}

    #{related}
      
    """
  end

  def func_doc(description, opts \\ []) do
    description = render_description(description)
    example = render_example(opts[:example])
    related = render_related(opts[:related])
    warning = render_warning(opts[:warning])
    success = opts[:success]
    failure = opts[:failure]
    signature = render_func_sig(opts[:params], success, failure)

    """
    #{description}

    #{warning}

    #{signature}

    #{example}

    #{related}
      
    """
  end

  def readme do
    "README.md" |> File.read!() |> String.replace("(#", "(#module-")
  end

  defp render_func_sig(params, success, failure) do
    header = "###  Parameters "

    table_header =
      String.trim("""
      | Parameter | Description   |
      |--------|-----------------------|
      """)

    table_contents =
      Enum.map_join(params, "\n", fn {k, v} ->
        if String.starts_with?("#{k}", "opts") && "#{k}" != "opts" do
          "| `#{k}`   | #{render_param_value(v)} |"
        else
          "| *#{k}*   | #{render_param_value(v)} |"
        end
      end)

    _returns =
      if success && failure do
        "Returns: <pre>#{success}</pre> or <pre>#{failure}</pre>"
      else
        if success, do: "Returns: <pre>#{success}</pre>", else: ""
      end

    """
    #{header}
      
    #{table_header}
    #{table_contents}


    """
  end

  defp render_ogc_common(nil), do: ""

  defp render_ogc_common(block) do
    """
    > #### From OWS Common Specification {: .info}
    >
    > #{block}
    """
  end

  defp render_warning(nil), do: ""

  defp render_warning({heading, message}) do
    """
    > #### #{heading} {: .warning}
    >
    > #{message}
    """
  end

  defp render_param_value(v) when is_bitstring(v), do: v

  defp render_param_value(v) do
    render_key(v)
  end

  defp render_keys(nil), do: ""

  defp render_keys(m) when is_map(m) do
    header = "### Keys"

    rendered_keys =
      Enum.map_join(m, "\n", fn {k, v} ->
        render_key(k, v)
      end)

    """
    #{header}

    #{rendered_keys}

    """
  end

  defp render_key({mod, name, :list}) do
    cleaned = String.replace("#{mod}", "Elixir.", "")
    "[`t:#{cleaned}.#{name}/0`]"
  end

  defp render_key({mod, name}) do
    cleaned = String.replace("#{mod}", "Elixir.", "")
    "`t:#{cleaned}.#{name}/0`"
  end

  defp render_key(k, {mod, name, :list}) do
    cleaned = String.replace("#{mod}", "Elixir.", "")
    "* **#{k}** :: [`t:#{cleaned}.#{name}/0`]"
  end

  defp render_key(k, {mod, name}) do
    cleaned = String.replace("#{mod}", "Elixir.", "")
    "* **#{k}** :: `t:#{cleaned}.#{name}/0`"
  end

  defp render_key(k, v) do
    cleaned = String.replace("#{v}", "Elixir.", "")
    "* **#{k}** :: `t:#{cleaned}.#{k}/0`"
  end

  defp render_example(nil), do: ""

  defp render_example(example) do
    """
    ### Examples

    ```elixir
    #{example}
    ```

    """
  end

  defp render_description(des_list) when is_list(des_list) do
    Enum.map_join(des_list, "\n", fn line ->
      "#{line}\n"
    end)
  end

  defp render_description(des), do: des

  defp render_related(nil), do: ""

  defp render_related(related_list) do
    related_list
    |> Enum.map(fn rel ->
      cleaned = String.replace("#{rel}", "Elixir.", "")
      "`#{cleaned}`"
    end)
    |> related()
  end

  defp resources do
    "### Resources
  * OGC
    * #{see_wmts_spec()}
    * #{see_ogc_common_spec()}
  * #{contact_maintainer()}
    * #{maintainer_github()}
    * #{see_link("Elixir Form: camatcode", "https://elixirforum.com/u/camatcode/", "⚗️")}
    * #{maintainer_fediverse()}
    * #{see_link("bsky: @ckcook.studiocms.io", "https://bsky.app/profile/ckcook.studiocms.io", "🦋️")}
    "
  end

  defp maintainer_github, do: "👾 [Github: camatcode](https://github.com/camatcode/){:target=\"_blank\"}"

  defp maintainer_fediverse,
    do: "🐘 [Fediverse: @scrum_log@maston.social](https://mastodon.social/@scrum_log){:target=\"_blank\"}"

  defp contact_maintainer, do: "Contact the maintainer (he's happy to help!)"

  defp see_wmts_spec do
    see_link("OGC WMTS Specification", "https://portal.ogc.org/files/?artifact_id=35326")
  end

  defp see_ogc_common_spec do
    see_link("OGC Common Specification", "https://portal.ogc.org/files/?artifact_id=38867")
  end

  defp see_link(title, url, emoji \\ "📖") do
    "#{emoji} [#{title}](#{url}){:target=\"_blank\"}"
  end

  defp related(related_list) do
    header = "### See Also "

    related_block =
      Enum.map_join(related_list, "\n", fn related ->
        "  * #{related}"
      end)

    """
    #{header}
    #{related_block}
    """
  end
end
