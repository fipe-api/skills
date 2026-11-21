# FIPE API skills

Agent skills to find Brazilian vehicle prices in the FIPE table. The skills use the FIPE API MCP server at `https://mcp.fipe.api.br/mcp`.

## Skills

| Skill | Use |
| --- | --- |
| `fipe-price-lookup` | Find the price from brand, model and year, or from a FIPE code. |
| `fipe-plate-lookup` | Find the vehicle and price from a license plate. Needs a subscription token. |
| `fipe-price-history` | Show the price over time and calculate depreciation. |
| `fipe-compare` | Compare vehicles, versions or model years. |
| `fipe-go-sdk` | Help a developer add FIPE prices to a Go application with the Go SDK. |
| `fipe-csharp-sdk` | Help a developer add FIPE prices to a .NET application with the C# SDK. |

## Install in Claude Code

Add the marketplace and install the plugin:

```sh
/plugin marketplace add fipe-api/skills
/plugin install fipe@fipe-api
```

The plugin adds the `fipe` MCP server from `.mcp.json`.

## Install the MCP server only

```sh
claude mcp add --transport http fipe https://mcp.fipe.api.br/mcp
```

## Other agents

Each skill is a folder in `skills/` with a `SKILL.md` file. Copy the folders to the skills directory of your agent. Connect the agent to `https://mcp.fipe.api.br/mcp`.

## Authentication

The MCP server uses OAuth. After you install the plugin, run `/mcp`, select `fipe` and sign in.

`get_vehicle_by_plate` and `get_price_history` need a FIPE API subscription. The other tools are free.

## Structure

```
.claude-plugin/
  plugin.json
  marketplace.json
.mcp.json
skills/
  fipe-price-lookup/SKILL.md
  fipe-plate-lookup/SKILL.md
  fipe-price-history/SKILL.md
  fipe-compare/SKILL.md
  fipe-go-sdk/SKILL.md
  fipe-go-sdk/references/recipes.md
  fipe-csharp-sdk/SKILL.md
  fipe-csharp-sdk/references/recipes.md
```

## Evals

The `evals/` directory has test cases for the skills. The cases use mocks of the MCP server. The mocks contain real FIPE data, so the tests do not need a login or a network connection to the FIPE API.

| Case | Skill | Check |
| --- | --- | --- |
| `lookup-by-fipe-code` | `fipe-price-lookup` | Price from a FIPE code. |
| `lookup-by-name` | `fipe-price-lookup` | Price from brand, model and year. |
| `ambiguous-model` | `fipe-price-lookup` | Asks for the version. Does not select one. |
| `zero-km` | `fipe-price-lookup` | Shows "Zero KM", not `32000`. |
| `plate-invalid` | `fipe-plate-lookup` | Does not send a plate that is not valid. |
| `plate-no-subscription` | `fipe-plate-lookup` | Normalizes the plate. Offers a lookup by brand, model and year. |
| `plate-no-fipe-price` | `fipe-plate-lookup` | Does not invent a price. |
| `history-free-fallback` | `fipe-price-history` | Gets the prices month by month without a subscription. |
| `compare-years` | `fipe-compare` | Compares two model years. |

Run all cases with a comparison to Claude without the plugin:

```sh
claude plugin eval .
```

Run each case one time, without the comparison:

```sh
claude plugin eval . --runs 1 --ablation none
```

### SDK cases

These cases ask Claude to write code with an SDK in an empty directory. Each case has the tag `sdk`.

| Case | Skill | Check |
| --- | --- | --- |
| `go-price-by-fipe-code` | `fipe-go-sdk` | Uses `VehicleByFipeCode`, keeps money in cents, sets the token option, tests with a fake server, and `go test` passes. |
| `go-history-subscription` | `fipe-go-sdk` | Uses `HistoryByFipeCode`, handles status 402, tests the 402 case, and `go test` passes. |
| `csharp-price-di` | `fipe-csharp-sdk` | Uses `GetVehicleByFipeCodeAsync`, keeps money in `decimal`, registers the client with `IHttpClientFactory`, tests with a stub handler, and `dotnet build` has no errors. |
| `csharp-history-subscription` | `fipe-csharp-sdk` | Uses `GetHistoryByFipeCodeAsync`, handles status 402, tests the 402 case, and `dotnet build` has no errors. |

The SDK cases need Bash and file writes. A scaffold script fills the Go module cache and the NuGet cache before each run, because the Bash sandbox can block network access:

```sh
claude plugin eval . --tag sdk --scaffold \
  --allow-tools Bash Write Edit \
  "WebFetch(domain:proxy.golang.org)" "WebFetch(domain:sum.golang.org)" \
  "WebFetch(domain:api.nuget.org)" "WebFetch(domain:globalcdn.nuget.org)"
```

The macOS sandbox does not let `dotnet test` start its test host. Thus the C# cases check that the code builds and that the tests exist, but they do not run the tests.

To run only the MCP cases, use `--tag lookup --tag plate --tag history --tag compare`.

## License

MIT. See [LICENSE](LICENSE).
