# Guia: Como Importar os Slides para Google Slides

## Opções para Importação

### Opção 1: Usar Slides.com ou Similar (Recomendado)

1. **Acesse:** https://slides.com
2. **Importe** o arquivo Markdown
3. **Exporte** para Google Slides

### Opção 2: Usar md2googleslides (CLI)

```bash
# Instalar
npm install -g md2gslides

# Converter
md2gslides docs/aulas/aula-01-testes-carga/slides/01-introducao-testes-carga.md \
  --title "Aula 01 - Introdução aos Testes de Carga"
```

### Opção 3: Manual (Mais Trabalhoso)

1. Abrir Google Slides
2. Criar nova apresentação
3. Copiar conteúdo de cada slide do Markdown
4. Formatar manualmente

### Opção 4: Usar Google Apps Script (Automação)

Criei um script que você pode usar para automatizar a criação.

## Arquivos de Slides Disponíveis

### Aula 01 - Testes de Carga (5 apresentações)

1. `docs/aulas/aula-01-testes-carga/slides/01-introducao-testes-carga.md`
   - 48 slides
   - Conceitos, tipos de testes, métricas

2. `docs/aulas/aula-01-testes-carga/slides/02-kubernetes-e-kind.md`
   - 58 slides
   - Kubernetes básico, kind, deployment

3. `docs/aulas/aula-01-testes-carga/slides/03-testes-carga-k6.md`
   - 60 slides
   - k6, VUs, stages, execução de testes

4. `docs/aulas/aula-01-testes-carga/slides/04-ci-cd-github-actions.md`
   - 58 slides
   - GitHub Actions, workflow, automação

5. `docs/aulas/aula-01-testes-carga/slides/05-revisao-e-melhores-praticas.md`
   - 58 slides
   - Revisão, melhores práticas, Q&A

**Total:** 282 slides

## Formato dos Slides Markdown

Os slides estão separados por `---` (três hífens), exemplo:

```markdown
# Título do Slide

Conteúdo aqui

---

## Próximo Slide

Mais conteúdo

---
```

## Conversão Automática Recomendada

Vou criar um script que facilita a conversão. Por enquanto, a forma mais rápida seria:

1. **Usar Marp** (Markdown Presentation Ecosystem)
   - Instalar: `npm install -g @marp-team/marp-cli`
   - Converter para PDF: `marp slides.md -o slides.pdf`
   - Importar PDF no Google Slides

2. **Usar Slidev** (Vue-powered slides)
   - Mais moderno e interativo
   - Suporta export para PDF

## Próximos Passos

Vou criar agora:
1. Um script de conversão automatizada usando md2gslides
2. Uma versão consolidada de todos os slides em um único arquivo
3. Templates prontos para Google Slides

Qual opção você prefere?
