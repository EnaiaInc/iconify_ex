defmodule Mix.Tasks.Iconify.Generate do
  @moduledoc """
  Generates CSS for all icons used in the project.

  This task scans your project's source files for iconify usage and
  generates the CSS file with all required icons.

  ## Usage

      $ mix iconify.generate

  ## Options

      * `--paths` - comma-separated paths to scan (default: lib)
      * `--extensions` - comma-separated file extensions (default: ex,heex)

  ## When to run

  Run this task during development after adding new icons, or in CI
  to ensure the CSS file is up to date:

      $ mix iconify.setup        # ensure JSON files are available
      $ mix iconify.generate     # generate CSS from source files

  """

  @shortdoc "Generates CSS for all icons used in the project"

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [paths: :string, extensions: :string])

    # Start the application to load config
    Mix.Task.run("app.start", ["--no-start"])

    paths = (opts[:paths] || "lib") |> String.split(",") |> Enum.map(&String.trim/1)
    extensions = (opts[:extensions] || "ex,heex") |> String.split(",") |> Enum.map(&String.trim/1)

    Mix.shell().info("Scanning for icons in: #{Enum.join(paths, ", ")}")
    Mix.shell().info("File extensions: #{Enum.join(extensions, ", ")}")

    icons = find_icons(paths, extensions)

    Mix.shell().info("Found #{length(icons)} unique icons")

    if icons == [] do
      Mix.shell().info("No icons found.")
    else
      generate_icons(icons)
      Mix.shell().info("Done!")
    end
  end

  defp find_icons(paths, extensions) do
    pattern = ~r/icon=["']([^"'@{%]+)["']/

    paths
    |> Enum.flat_map(fn path ->
      extensions
      |> Enum.flat_map(fn ext ->
        Path.wildcard("#{path}/**/*.#{ext}")
      end)
    end)
    |> Enum.flat_map(fn file ->
      file
      |> File.read!()
      |> then(&Regex.scan(pattern, &1))
      |> Enum.map(fn [_, icon] -> icon end)
    end)
    |> Enum.reject(&String.starts_with?(&1, "/"))  # Reject file paths like /images/foo.svg
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp generate_icons(icons) do
    Enum.each(icons, fn icon ->
      Mix.shell().info("Generating: #{icon}")
      Iconify.prepare(%{icon: icon, __changed__: nil})
    end)
  end
end
