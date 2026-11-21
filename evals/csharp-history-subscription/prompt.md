---
description: Write a .NET method for the price history that handles the subscription error, with tests.
tags: [sdk, csharp]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, ToolSearch]
---

Crie neste diretório uma solução .NET com dois projetos: a class library src/FipeHistory e o projeto de testes xUnit tests/FipeHistory.Tests. Use a versão do .NET que está instalada. Em src/FipeHistory/PriceHistoryService.cs, crie a classe PriceHistoryService, que recebe um FipeClient no construtor, com o método Task<IReadOnlyList<MonthlyPrice>> GetMonthlyPricesAsync(string fipeCode, string yearCode, CancellationToken cancellationToken), usando o SDK oficial da FIPE para C# (pacote Fipe.Api.Br). MonthlyPrice é um record com Month (string) e Price (decimal). Quando a API exigir assinatura, lance SubscriptionRequiredException. Escreva os testes em tests/FipeHistory.Tests/PriceHistoryServiceTests.cs e rode dotnet build até compilar sem erros. Este ambiente não tem rede e não permite rodar dotnet test: use só os pacotes que já estão no cache do NuGet (~/.nuget/packages), e o build com -m:1 -nodeReuse:false.
