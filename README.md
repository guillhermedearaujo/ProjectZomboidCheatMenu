# Painel de Cheats para Project Zomboid (Singleplayer)

Painel de cheats em Lua para **Project Zomboid (Build 42.20.0)**. Abre uma janela com abas para dar a si mesmo armas, munição, itens e habilidades sem precisar de consola.

## O que resolve

- Elimina a necessidade de digitar comandos de consola (ou usar mods pesados de debug) para testar conteúdo em singleplayer.
- Permite obter de forma rápida: armas de fogo e brancas, munição, proteção, mochilas, itens de construção, veículos, itens diversos e **livros de conhecimento** (que concedem receitas e níveis de habilidade instantaneamente).

## Abas do painel

| Aba | O que faz |
| --- | --- |
| Armas de Fogo | Dá armas de fogo com pentes/carregadores cheios |
| Armas Brancas | Dá armas corpo a corpo |
| Municao | Dá munição solta e cartuchos cheios |
| Protecao | Dá coletes, capacetes e coldres |
| Mochilas | Dá mochilas e bolsas |
| Itens | Dá itens de ferramenta/material/eletrônica/container |
| Construcao | Dá tábuas, martelos, serrotes, pregos, parafusos, botijões de gás e maçarico |
| Veiculos | Adiciona veículos com tanque cheio |
| Conhecimento | Livros: clica para aprender receitas e o nível da habilidade do livro |

## Pré-requisitos

- **Project Zomboid** versão **42.20.0** (modo singleplayer).
- Não é necessário Python/npm — é um mod 100% Lua do próprio jogo.

## Instalação (onde extrair)

1. Baixe o repositório como **ZIP** (botão `Code` → `Download ZIP`) ou clone com git:
   ```
   git clone https://github.com/SEU_USUARIO/CheatPanel.git
   ```
2. Extraia o conteúdo de forma que a pasta `CheatPanel` fique dentro da pasta de mods do jogo:

   ```
   C:\Users\SEU_USUARIO\Zomboid\mods\CheatPanel\
   ├── mod.info
   ├── media\
   │   └── lua\
   │       └── client\
   │           └── CheatPanel.lua
   └── docs\            (capturas de tela, opcional)
   ```

   Ou seja: o destino final deve ser `C:\Users\SEU_USUARIO\Zomboid\mods\CheatPanel\mod.info`.

3. Abra o Project Zomboid → menu principal → **Mods** → habilite **"Painel de Cheats"**.
4. Inicie/carregue uma partida **singleplayer**.

## Como usar

- Pressione **F7** em qualquer momento dentro do jogo para abrir/fechar o painel.
- Há também um botão **"Cheats"** no canto superior direito da tela.
- Selecione um item na aba e clique no botão **"Dar"** (ou use a quantidade ao lado).
- Na aba **Conhecimento**, clique em um livro para aprender as receitas e o nível da habilidade de uma vez.

## Como desinstalar

1. Desative o mod no menu **Mods** do jogo.
2. Apague a pasta `C:\Users\SEU_USUARIO\Zomboid\mods\CheatPanel`.

## Estrutura do repositório

```
CheatPanel/
├── mod.info                  # Definição do mod (nome, id, versão)
├── media/
│   └── lua/
│       └── client/
│           └── CheatPanel.lua  # Todo o código do painel
├── docs/                     # Capturas de tela e diagramas
├── .gitignore                # Arquivos ignorados no versionamento
└── README.md
```

> Observação: a pasta `media/lua/client` é o caminho obrigatório do Project Zomboid para scripts de cliente — por isso não é usado `src/` nem `scripts/` neste projeto.

## Limitações

- Feito e testado somente para **singleplayer** (não é um console de administrador de servidor).
- Utiliza APIs internas do jogo; pode quebrar em outras builds além da 42.20.0.

## Licença

Uso livre para fins de estudo e testes pessoais. Não afiliado à The Indie Stone.