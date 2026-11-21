---
description: Write a .NET service that gets a FIPE price with the C# SDK and registers it in DI, with tests.
tags: [sdk, csharp]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, ToolSearch]
---

Crie neste diretório uma solução .NET com dois projetos: a class library src/FipePrice e o projeto de testes xUnit tests/FipePrice.Tests. Use a versão do .NET que está instalada. Em src/FipePrice/VehiclePriceService.cs, crie a classe VehiclePriceService com o método Task<decimal> GetPriceAsync(string fipeCode, string yearCode, CancellationToken cancellationToken) que retorna o preço FIPE atual de um carro, usando o SDK oficial da FIPE para C#. Em src/FipePrice/ServiceCollectionExtensions.cs, crie o método AddFipePrice(this IServiceCollection services, IConfiguration configuration) que registra tudo no DI. Escreva os testes em tests/FipePrice.Tests/VehiclePriceServiceTests.cs e rode dotnet build até compilar sem erros. Este ambiente não tem rede e não permite rodar dotnet test: use só os pacotes que já estão no cache do NuGet (~/.nuget/packages), e o build com -m:1 -nodeReuse:false.
