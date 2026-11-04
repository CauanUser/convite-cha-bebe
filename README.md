# Convite digital — Chá de fraldas de Samuel Felipe

Convite interativo e responsivo, desenvolvido em HTML, CSS e JavaScript puro e publicado gratuitamente pelo GitHub Pages.

## O que o convite oferece

- Abertura animada em formato de envelope.
- Apresentação do evento, data, horário, local e contagem regressiva.
- Navegação rápida entre as seções.
- História da família, linha do tempo, fotos, ultrassons e vídeos (com espaços reservados até a inclusão dos arquivos reais).
- Escolha do tamanho de fralda (RN, P, M, G ou XG) e quantidade de pacotes.
- Seleção de presentes complementares e quantidade de cada item.
- Resumo da seleção antes de confirmar.
- Formulário de presença com nome e telefone opcional.
- Mensagem pronta enviada ao WhatsApp dos responsáveis.

## Como personalizar

Abra `index.html` e edite os objetos `CONVITE` e `CONTEUDO_ESPECIAL`, próximos ao início do script.

No objeto `CONVITE`, personalize:

- `nomeBebe`: nome do bebê.
- `titulo` e `mensagem`: título e texto do convite.
- `dataTexto`: data exibida aos convidados.
- `dataISO`: data e horário para a contagem regressiva, no formato `AAAA-MM-DDTHH:MM:SS`.
- `horario` e `local`: horário e endereço do evento.
- `whatsapp`: número dos responsáveis com DDI e DDD, somente números.
- `mapaURL`: link do Google Maps (vazio para ocultar o botão).
- `encerramento`: frase final.

No objeto `CONTEUDO_ESPECIAL`, personalize os textos, fotos, ultrassons, momentos da gestação, presentes e vídeos. Para fotos e vídeos, informe o caminho do arquivo no projeto em `src`.

**Importante:** o número de WhatsApp atual é provisório. Troque-o pelo número autorizado dos responsáveis antes de divulgar o convite.

## Publicar pelo GitHub Pages

1. Abra **Settings → Pages** no repositório.
2. Em **Build and deployment**, selecione **Deploy from a branch**.
3. Escolha a branch `main` e a pasta `/(root)`.
4. Salve e aguarde a publicação.

Site: https://cauanuser.github.io/convite-cha-bebe/

## Funcionamento e privacidade

- O projeto é estático e não utiliza servidor ou banco de dados.
- A seleção de presentes é incluída na mensagem preparada para o WhatsApp.
- Ao confirmar, o navegador abre o WhatsApp; o convidado ainda precisa tocar em **Enviar**.
- O site não salva reservas, não controla estoque e não informa aos responsáveis que a mensagem foi efetivamente enviada.
- Não coloque informações pessoais de terceiros ou fotos reais sem autorização.
- Use conteúdo fictício enquanto prepara a demonstração.
