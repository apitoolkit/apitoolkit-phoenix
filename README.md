<div align="center">

![APItoolkit's Logo](https://github.com/apitoolkit/.github/blob/main/images/logo-white.svg?raw=true#gh-dark-mode-only)
![APItoolkit's Logo](https://github.com/apitoolkit/.github/blob/main/images/logo-black.svg?raw=true#gh-light-mode-only)

## Phoenix SDK

[![APItoolkit SDK](https://img.shields.io/badge/APItoolkit-SDK-0068ff?logo=elixir)](https://github.com/topics/apitoolkit-sdk) [![Join Discord Server](https://img.shields.io/badge/Chat-Discord-7289da)](https://discord.gg/dEB6EjQnKB) [![APItoolkit Docs](https://img.shields.io/badge/Read-Docs-0068ff)](https://apitoolkit.io/docs/sdks/elixir/phoenix?utm_source=github-sdk) 

APItoolkit is an end-to-end API and web services management toolkit for engineers and customer support teams. To integrate `.Net` web services with APItoolkit, you need to use this SDK to monitor incoming traffic, aggregate the requests, and then deliver them to the APItoolkit's servers.

</div>

---

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Contributing and Help](#contributing-and-help)
- [License](#license)

---

## Installation

To install the SDK, kindly add `apitoolkit_phoenix` to your list of dependencies in the `mix.exs` file like so:

```elixir
def deps do
  [
    {:apitoolkit_phoenix, "~> 0.1.1"}
  ]
end
```

Then, run the `mix deps.get` command to install the `apitoolkit_phoenix` dependency.

## Configuration

Next, import and initialize the `ApitoolkitPhoenix` Plug in your `router.ex` file like so:

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router
  use Plug.ErrorHandler
  import ApitoolkitPhoenix

  pipeline :api do
    plug :accepts, ["json"]
    # Other plugs
    plug ApitoolkitPhoenix,
      config: %{
        api_key: "{ENTER_YOUR_API_KEY_HERE}",
      }
  end
end
```

> [!NOTE]
> 
> The `{ENTER_YOUR_API_KEY_HERE}` demo string should be replaced with the [API key](https://apitoolkit.io/docs/dashboard/settings-pages/api-keys?utm_source=github-sdk) generated from the APItoolkit dashboard.

<br />

> [!IMPORTANT]
> 
> To learn more configuration options (redacting fields, error reporting, outgoing requests, etc.) please read our comprehensive [Phoenix SDK](https://apitoolkit.io/docs/sdks/elixir/phoenix?utm_source=github-sdk) documentation.

## Contributing and Help

To contribute to the development of this SDK or request help from the community and our team, kindly do any of the following:
- Read our [Contributors Guide](https://github.com/apitoolkit/.github/blob/main/CONTRIBUTING.md).
- Join our community [Discord Server](https://discord.gg/dEB6EjQnKB).
- Create a [new issue](https://github.com/apitoolkit/apitoolkit-dotnet/issues/new/choose) in this repository.

## License

This repository is published under the [MIT](LICENSE) license.

---

<div align="center">
    
<a href="https://apitoolkit.io?utm_source=apitoolkit_github_dotnetsdk" target="_blank" rel="noopener noreferrer"><img src="https://github.com/apitoolkit/.github/blob/main/images/icon.png?raw=true" width="40" /></a>

</div>
