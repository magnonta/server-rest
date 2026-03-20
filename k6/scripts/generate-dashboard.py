#!/usr/bin/env python3
"""
Gera dashboard HTML interativo com métricas de scaling do cluster K8s.
Entrada: CSV com métricas coletadas durante os testes de carga.
Saída: HTML auto-contido com gráficos interativos (hover, zoom, pan).

Uso: python3 generate-dashboard.py <csv_entrada> <diretorio_saida>
"""

import sys
import os

try:
    import pandas as pd
    import plotly.graph_objects as go
    from plotly.subplots import make_subplots
except ImportError:
    print("AVISO: plotly/pandas não instalados. Pulando geração de dashboard.")
    sys.exit(0)

csv_path = sys.argv[1] if len(sys.argv) > 1 else "k6/results/cluster-metrics.csv"
out_dir = sys.argv[2] if len(sys.argv) > 2 else "k6/results"

if not os.path.exists(csv_path):
    print(f"AVISO: Arquivo {csv_path} não encontrado. Pulando.")
    sys.exit(0)

df = pd.read_csv(csv_path)

if len(df) < 2:
    print("AVISO: Dados insuficientes para gerar dashboard.")
    sys.exit(0)

# Converter elapsed_sec para minutos para melhor legibilidade
df["elapsed_min"] = df["elapsed_sec"] / 60.0

fig = make_subplots(
    rows=3,
    cols=2,
    shared_xaxes=True,
    vertical_spacing=0.08,
    horizontal_spacing=0.10,
    subplot_titles=[
        "CPU HPA - Utilização (%)",
        "Memória HPA - Utilização (%)",
        "Réplicas HPA (atual vs desejado)",
        "Pods em Execução",
        "CPU Total dos Pods (millicores)",
        "Memória Total dos Pods (MiB)",
    ],
)

# Linha de threshold do HPA
cpu_threshold = [50] * len(df)
mem_threshold = [80] * len(df)

# 1. CPU HPA
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["hpa_cpu_pct"],
        name="CPU (%)",
        line=dict(color="#ef553b", width=2.5),
        fill="tozeroy",
        fillcolor="rgba(239,85,59,0.15)",
    ),
    row=1,
    col=1,
)
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=cpu_threshold,
        name="Threshold CPU (50%)",
        line=dict(color="#ef553b", width=1, dash="dash"),
        showlegend=True,
    ),
    row=1,
    col=1,
)

# 2. Memória HPA
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["hpa_mem_pct"],
        name="Memória (%)",
        line=dict(color="#636efa", width=2.5),
        fill="tozeroy",
        fillcolor="rgba(99,110,250,0.15)",
    ),
    row=1,
    col=2,
)
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=mem_threshold,
        name="Threshold Mem (80%)",
        line=dict(color="#636efa", width=1, dash="dash"),
        showlegend=True,
    ),
    row=1,
    col=2,
)

# 3. Réplicas
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["current_replicas"],
        name="Réplicas (atual)",
        line=dict(color="#00cc96", width=2.5),
        mode="lines+markers",
        marker=dict(size=4),
    ),
    row=2,
    col=1,
)
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["desired_replicas"],
        name="Réplicas (desejado)",
        line=dict(color="#00cc96", width=1.5, dash="dot"),
    ),
    row=2,
    col=1,
)

# 4. Pod count
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["pod_count"],
        name="Pods Running",
        line=dict(color="#ab63fa", width=2.5),
        fill="tozeroy",
        fillcolor="rgba(171,99,250,0.15)",
    ),
    row=2,
    col=2,
)

# 5. CPU Total
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["total_cpu_millicores"],
        name="CPU Total (m)",
        line=dict(color="#ffa15a", width=2.5),
        fill="tozeroy",
        fillcolor="rgba(255,161,90,0.15)",
    ),
    row=3,
    col=1,
)

# 6. Memória Total
fig.add_trace(
    go.Scatter(
        x=df["elapsed_min"],
        y=df["total_mem_mib"],
        name="Memória Total (MiB)",
        line=dict(color="#19d3f3", width=2.5),
        fill="tozeroy",
        fillcolor="rgba(25,211,243,0.15)",
    ),
    row=3,
    col=2,
)

# Layout geral (tema escuro estilo Grafana)
fig.update_layout(
    title=dict(
        text="Dashboard de Scaling - Kubernetes HPA + Load Testing",
        font=dict(size=20),
    ),
    template="plotly_dark",
    height=900,
    width=1300,
    showlegend=True,
    legend=dict(orientation="h", yanchor="bottom", y=-0.12, xanchor="center", x=0.5),
    font=dict(family="Inter, system-ui, -apple-system, sans-serif"),
    paper_bgcolor="#0b0e11",
    plot_bgcolor="#181b1f",
)

# Labels dos eixos X na última linha
fig.update_xaxes(title_text="Tempo (min)", row=3, col=1)
fig.update_xaxes(title_text="Tempo (min)", row=3, col=2)

os.makedirs(out_dir, exist_ok=True)
html_path = os.path.join(out_dir, "cluster-scaling-dashboard.html")
fig.write_html(html_path, include_plotlyjs=True)
print(f"Dashboard salvo em {html_path}")

# Tentar gerar PNG também (precisa de kaleido)
try:
    png_path = os.path.join(out_dir, "cluster-scaling-dashboard.png")
    fig.write_image(png_path, scale=2)
    print(f"Imagem salva em {png_path}")
except Exception:
    print("AVISO: kaleido não disponível, PNG não gerado (apenas HTML).")
