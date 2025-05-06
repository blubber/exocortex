defmodule ChatWeb.Layouts do
  use ChatWeb, :html

  embed_templates "layouts/*"

  attr :class, :any, default: nil
  attr :current_scope, :map, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :any, default: nil
  attr :current_scope, :map, default: nil

  slot :inner_block, required: true

  def focus(assigns) do
    ~H"""
    <main class={["mx-auto max-w-sm p-2 md:p-4 mt-16 md:mt-24", @class]} aria-live="polite">
      <div class="w-full">
        {render_slot(@inner_block)}
      </div>
    </main>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
