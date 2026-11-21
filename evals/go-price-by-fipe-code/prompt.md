---
description: Write a Go package that gets a FIPE price with the Go SDK, with tests.
tags: [sdk, go]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, ToolSearch]
---

Crie um módulo Go neste diretório (module example.com/fipeprice, package fipeprice). No arquivo price.go, crie a função PriceInCents(ctx context.Context, fipeCode, yearCode string) (int64, error) que retorna o preço FIPE atual de um carro em centavos, usando o SDK oficial da FIPE para Go. Escreva os testes em price_test.go e rode go test até passar. Este ambiente não tem acesso garantido à rede: o SDK v0.1.0 já está no cache de módulos do Go.
