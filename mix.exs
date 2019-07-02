defmodule Defnamed.MixProject do
  use Mix.Project

  def project do
    [
      app: :defnamed,
      version: "VERSION" |> File.read!() |> String.trim(),
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      # excoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.travis": :test,
        "coveralls.circle": :test,
        "coveralls.semaphore": :test,
        "coveralls.post": :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      # dialyxir
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore",
        plt_add_apps: [
          :mix,
          :ex_unit
        ]
      ],
      # ex_doc
      name: "Defnamed",
      source_url: "https://github.com/coingaming/defnamed",
      homepage_url: "https://github.com/coingaming/defnamed",
      docs: [main: "readme", extras: ["README.md"]],
      # hex.pm stuff
      description: "compile-time named arguments for Elixir functions and macro",
      package: [
        licenses: ["Apache 2.0"],
        files: ["lib", "priv", "mix.exs", "README*", "VERSION*"],
        maintainers: ["Ilja Tkachuk AKA timCF"],
        links: %{
          "GitHub" => "https://github.com/coingaming/defnamed",
          "Author's home page" => "https://itkach.uk"
        }
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # development tools
      {:excoveralls, "~> 0.8", runtime: false, only: [:dev, :test]},
      {:dialyxir, "~> 0.5", runtime: false, only: [:dev, :test]},
      {:ex_doc, "~> 0.19", runtime: false, only: [:dev, :test]},
      {:credo, "~> 0.9", runtime: false, only: [:dev, :test]},
      {:boilex, "~> 0.2", runtime: false, only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      docs: ["docs", "cmd mkdir -p doc/priv/img/", "cmd cp -R priv/img/ doc/priv/img/", "docs"]
    ]
  end
end
