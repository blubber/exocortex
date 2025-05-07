defmodule Chat.Utils do
  def format_content(content) when is_binary(content) do
    MDEx.to_html(content,
      extension: [
        strikethrough: true,
        table: true,
        superscript: true,
        footnotes: true,
        description_lists: true,
        multiline_block_quotes: true,
        math_dollars: true,
        math_code: true,
        underline: true,
        subscript: true
      ],
      parse: [smart: true],
      render: [escape: true, full_info_string: true],
      features: [syntax_highlight_theme: nil]
    )
  end

  def format_content({:ok, content}) when is_binary(content), do: format_content(content)
  def format_content({:error, _} = error), do: error

  def format_user_content(content_raw) when is_binary(content_raw) do
    case format_content(content_raw) do
      {:ok, content} -> content
      _ -> content_raw
    end
  end
end
