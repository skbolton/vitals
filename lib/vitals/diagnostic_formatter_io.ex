defmodule Vitals.DiagnosticFormatter.IO do
  alias Vitals.DiagnosticTable.State

  def format(%State{diagnostics: diagnostics}, :io) do
    diagnostics
    |> to_table()
    |> Enum.map_join("\n", &Enum.join(&1, ": "))
    |> then(fn output -> output <> "\n" end)
    |> IO.write()
  end

  def format(%State{diagnostics: diagnostics}, :pretty) do
    [handlers, diagnostics] =
      diagnostics
      |> to_table()
      |> Enum.reduce([[], []], fn [handler, diag], [handlers, diagnostics] ->
        diag =
          case diag do
            :healthy ->
              format_string(diag, :black, :green)

            :degraded ->
              format_string(diag, :black, :yellow)

            :fatal ->
              format_string(diag, :black, :red)

            :initializing ->
              format_string(diag, :red, :light_black)
          end

        [[to_string(handler) | handlers], [diag | diagnostics]]
      end)

    handler_length = get_max_handler_length(handlers)

    Enum.zip_with(handlers, diagnostics, fn handler, diagnostics ->
      String.pad_trailing(handler, handler_length) <> diagnostics
    end)
    |> Enum.join("\n")
    |> then(fn handler_status -> handler_status <> "\n" end)
    |> IO.write()
  end

  defp get_max_handler_length(handlers) do
    length = Enum.max_by(handlers, &String.length/1) |> String.length()
    length + 4
  end

  defp to_table(diagnostics) do
    diagnostics
    |> Enum.map(fn
      {handler, nil} ->
        [handler, :initializing]

      {handler, diagnostic} ->
        [handler, diagnostic.status]
    end)
  end

  defp format_string(status, foreground, background) do
    background_color =
      case background do
        :green -> IO.ANSI.green_background()
        :yellow -> IO.ANSI.yellow_background()
        :red -> IO.ANSI.red_background()
        :light_black -> IO.ANSI.light_black_background()
      end

    text_color =
      case foreground do
        :black -> IO.ANSI.black()
        :red -> IO.ANSI.red()
      end

    background_color <> text_color <> "  #{status}  " <> IO.ANSI.reset()
  end
end
