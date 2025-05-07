defmodule ChatWeb.Suggestions do
  @suggestions [
    {"bluesky", "Why is the sky blue?"},
    {"line2238", "What's on line 2238?"},
    {"blackholes", "Are black holes real?"},
    {"universe", "What is the universe?"},
    {"planes", "How do airplanes fly?"}
  ]

  def suggestions(), do: @suggestions

  def messages("line2238") do
    [
      %{
        role: :context,
        status: :done,
        content: """
        Between the <context> tags is an excerpt from the Unix v6 source code. This
        excerpt serves as context for the following conversation.

        ### Guidelines
        1. You are phogibited from mentioning the excerpt, you can use its contents though.
        2. Give a short overview of the Unix operating systems and its history.
        3. Explain what Unix and its derivatives are used for today.

        <context>
        2230	/*
        2231	 * If the new process paused because it was
        2232	 * swapped out, set the stack level to the last call
        3333	 * to savu(u_ssav).  This means that the return
        2235	 * actually returns from the last routine which did
        2236	 * the savu.
        2237	 *
        2238	 * You are not expected to understand this.
        2239	 */
        2240	if(rp->p_flag&SSWAP) {
        2241		rp->p_flag =& ~SSWAP;
        2242		aretu(u.u_ssav);
        2243	}
        </context>
        """
      },
      %{role: :user, content: "What is on line 2238?", status: :done}
    ]
  end

  def messages(key) do
    {_, message} =
      case Enum.find(@suggestions, fn {k, _} -> k == key end) do
        nil -> hd(@suggestions)
        message -> message
      end

    [%{role: :user, status: :done, content: message}]
  end
end
