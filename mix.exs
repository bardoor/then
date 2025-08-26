defmodule Then.MixProject do
  use Mix.Project

  def project do
    [
      app: :then,
      version: "1.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Then",
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def description do
    "Simple way to set after-function callback"
  end

  def package do
    [
      name: "then",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bardoor/then"}
    ]
  end

  def application do
    [
      # nope
    ]
  end

  defp docs do
    [
      main: "then",
      source_url: "https://github.com/bardoor/then",
      extras: [
        "docs/then.md",
        "docs/changelog.md",
        "docs/license.md"
      ],
      groups_for_extras: [
        "Documentation": ["docs/then.md"],
        "Legal": ["docs/changelog.md", "docs/license.md"]
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
end
