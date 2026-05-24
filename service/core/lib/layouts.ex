defmodule Smith.Core.Layouts do
  @moduledoc "Minimal root layout for LiveView / LiveDashboard."

  use Phoenix.Component

  attr :inner_content, :any, required: true

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>RICE · SMITH</title>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
