---
description: Write a Go function for the price history that handles the subscription error, with tests.
tags: [sdk, go]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, ToolSearch]
---

Crie um módulo Go neste diretório (module example.com/fipehistory, package fipehistory). No arquivo history.go, crie a função MonthlyPrices(ctx context.Context, client *fipe.Client, fipeCode, yearCode string) ([]MonthlyPrice, error) usando o SDK oficial da FIPE para Go (github.com/fipe-api/go-sdk). MonthlyPrice tem Month (string) e Cents (int64). Quando a API exigir assinatura, retorne o erro exportado ErrSubscriptionRequired. Escreva os testes em history_test.go e rode go test até passar. Este ambiente não tem acesso garantido à rede: o SDK v0.1.0 já está no cache de módulos do Go.
