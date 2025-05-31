defmodule ChatWeb.CoreComponents do
  use Phoenix.Component
  use Gettext, backend: ChatWeb.Gettext

  import Phoenix.Component, except: [link: 1]

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :class, :any, default: nil

  slot :inner_block
  slot :header, required: false

  def menu(assigns) do
    ~H"""
    <focus_wrap
      id={@id}
      phx-hook="Menu"
      popover
      class={["p-2 md:p-4 pt-0 bg-transparent menu", @class]}
    >
      <div class="p-2 flex flex-col gap-4 bg-default text-default border-default rounded-lg shadow-lg shadow-black">
        <header class="flex flex-col gap-1">
          <div class="flex gap-4 items-center">
            <div class="flex-1">
              <.title level={4}>{@title}</.title>
            </div>
            <div>
              <button
                type="button"
                popovertarget={@id}
                popovertargetaction="hide"
                class="text-close-button p-1 cursor-pointer transition-all opacity-75 hover:opacity-100"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>
          </div>
          <div :if={@header != []}>
            {render_slot(@header)}
          </div>
        </header>

        <div>
          {render_slot(@inner_block)}
        </div>
      </div>
    </focus_wrap>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :rest, :global

  slot :inner_block, required: true
  slot :action, required: false

  def alert(assigns) do
    ~H"""
    <div popover id={@id} {@rest} class="m-auto w-full  md:min-w-md max-w-xl p-4 bg-transparent alert">
      <.focus_wrap id={"#{@id}-focus-wrap"}>
        <div
          class="bg-default text-default flex flex-col gap-4 md:gap-6 p-4 rounded-lg border-default shadow-lg shadow-black"
          role="alertdialog"
        >
          <header class="flex gap-4 items-center">
            <div class="flex-1">
              <.title level={4} class="text-lg">{@title}</.title>
            </div>
            <div>
              <button
                type="button"
                popovertarget={@id}
                popovertargetaction="hide"
                aria-label="Close alert"
                class="text-close-button p-1 cursor-pointer transition-all opacity-75 hover:opacity-100"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>
          </header>

          <div>
            {render_slot(@inner_block)}
          </div>

          <footer :if={@action != []} class="flex justify-end items-center gap-2">
            <div :for={action <- @action}>{render_slot(action)}</div>
          </footer>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def toolbar(assigns) do
    ~H"""
    <nav class={[
      "flex gap-1 fixed top-2 left-2 border-default px-2 py-1 rounded-lg bg-toolbar",
      @class
    ]}>
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr :level, :integer, default: 1
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def title(assigns) do
    ~H"""
    <.dynamic_tag tag_name={"h#{@level}"} class={["font-semibold trakcing-tight", @class]} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex flex-col gap-6", "pb-4", @class]}>
      <div>
        <.title class="text-lg md:text-xl leading-8 md:leading-10">
          {render_slot(@inner_block)}
        </.title>
        <p :if={@subtitle != []} class="text-sm text-muted">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex flex-row justify-end">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr :rest, :global, include: ~w(href navigate patch method)
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link
      class={["text-red-400/90 hover:text-red-400 underline hover:no-underline", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    """
  end

  attr :rest, :global,
    include: ~w(href navigate patch method popovertarget popovertargetaction disabled)

  attr :variant, :string, default: "primary"
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <Phoenix.Component.link class={[button_variant(@variant), @class]} {@rest}>
        {render_slot(@inner_block)}
      </Phoenix.Component.link>
      """
    else
      ~H"""
      <button class={[button_variant(@variant), @class]} @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  defp button_variant("blank") do
    button_style([])
  end

  defp button_variant("toolbar") do
    ~w(transition-all p-2 md:p-1.5 text-toolbar-button)
  end

  defp button_variant("link") do
    button_style(
      ~w(cursor-pointer text-red-400/90 hover:text-red-400 underline hover:no-underline)
    )
  end

  defp button_variant("primary") do
    button_style(~w(
      bg-linear-to-t from-red-500/85 to-red-500/90
      hover:not-disabled:from-red-500/96 hover:not-disabled:to-red-500
    ))
  end

  defp button_variant("danger") do
    ~w(
    rounded-md text-sm px-2 py-1 leading-6 cursor-pointer
    disabled:opacity-60 disabled:cursor-default
    bg-red-700 text-red-200
  )
  end

  defp button_style(class_list) do
    ~w(
      transition-all
      text-sm px-3 py-2 font-semibold disabled:opacity-75
  ) ++ class_list
  end

  attr :for, :string, required: true
  attr :required, :boolean, default: true

  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block w-full font-semibold text-sm">
      {render_slot(@inner_block)}
      <span :if={!@required} class="text-xs text-zinc-400">(optional)</span>
    </label>
    """
  end

  attr :id, :any, default: nil
  attr :label, :string, default: nil
  attr :field, Phoenix.HTML.FormField

  attr :errors, :list, default: []
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  slot :inner_block, required: true

  def fieldset(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> fieldset()
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :errors, :list, default: []

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="fieldset-label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      class={[
        "block w-full outline-none ring-0 rounded-md px-2 py-1 focus:ring-1",
        "bg-input border-input ring-input",
        @class
      ]}
      {@rest}
    >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="contents" aria-live="polite">
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && "#{@id}-error"}
        class={[
          "block w-full outline-none ring-0 rounded-md px-2 py-1 focus:ring-1",
          "bg-input border-input ring-input",
          @class
        ]}
        {@rest}
      />

      <.error :if={@errors != []} id={"#{@id}-error"}>{hd(@errors)}</.error>
    </div>
    """
  end

  attr :rest, :global

  slot :inner_block, required: true

  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error" {@rest}>
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div>
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  attr :id, :string
  attr :title, :string, required: true
  attr :rest, :global

  slot :header, required: false
  slot :inner_block, required: true
  slot :footer, required: false

  def dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Dialog"
      {@rest}
      class={[
        "border",
        "w-full bg-default text-default border-default rounded-lg shadow-lg shadow-black open:flex flex-col gap-2",
        "max-md:h-full max-md:top-[calc(1em+3px)] max-md:left-[calc(1em+3px)]",
        "md:max-w-xl md:mx-auto md:mt-12 md:max-h-[calc(100%-2em-6px-8rem)]"
      ]}
      aria-labelledby={"#{@id}-title"}
    >
      <header class="flex flex-col gap-2">
        <div class="flex gap-4 justify-between p-2 items-center">
          <div>
            <.title class="text-base md:text-lg" id={"#{@id}-title"}>{@title}</.title>
          </div>

          <div>
            <button
              type="button"
              class="text-close-button p-1 cursor-pointer transition-all opacity-75 hover:opacity-100"
              phx-click={JS.dispatch(":close", to: "##{@id}")}
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>
        </div>
        <div :if={@header != []}>
          {render_slot(@header)}
        </div>
      </header>
      <div class="flex-1 flex flex-col flex-1 overflow-y-auto p-2 md:p-4">
        {render_slot(@inner_block)}
      </div>
    </dialog>
    """
  end

  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ChatWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ChatWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
