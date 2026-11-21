# FIPE API skills

Agent skills to find Brazilian vehicle prices in the FIPE table. The skills use the FIPE API MCP server at `https://fipe.api.br/mcp`.

## Skills

| Skill | Use |
| --- | --- |
| `fipe-price-lookup` | Find the price from brand, model and year, or from a FIPE code. |
| `fipe-plate-lookup` | Find the vehicle and price from a license plate. Needs a subscription token. |
| `fipe-price-history` | Show the price over time and calculate depreciation. |
| `fipe-compare` | Compare vehicles, versions or model years. |

## Install in Claude Code

Add the marketplace and install the plugin:

```sh
/plugin marketplace add fipe-api/skills
/plugin install fipe@fipe-api
```

The plugin adds the `fipe` MCP server from `.mcp.json`.

## Install the MCP server only

```sh
claude mcp add --transport http fipe https://fipe.api.br/mcp
```

## Other agents

Each skill is a folder in `skills/` with a `SKILL.md` file. Copy the folders to the skills directory of your agent. Connect the agent to `https://fipe.api.br/mcp`.

## Tools that need a token

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
```

## License

MIT. See [LICENSE](LICENSE).
