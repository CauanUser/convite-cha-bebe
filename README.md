# Convite digital — Chá de bebê

Convite interativo em HTML, CSS e JavaScript, pronto para publicar no GitHub Pages.

## Como personalizar

Abra o arquivo `index.html` e edite o objeto `CONVITE`, no final do arquivo:

- `nomeBebe`: nome do bebê
- `titulo`: título do evento
- `mensagem`: texto do convite
- `dataTexto`: data exibida
- `dataISO`: data e horário para a contagem regressiva, no formato `AAAA-MM-DDTHH:MM:SS`
- `horario`: horário do evento
- `local`: endereço/local
- `whatsapp`: número com DDI e DDD, somente números
- `mensagemWhatsApp`: texto que será aberto no WhatsApp
- `mapaURL`: link do Google Maps (deixe vazio para ocultar o botão)
- `encerramento`: frase final

O WhatsApp está temporariamente configurado para **5585921957691**.

## Publicar no GitHub Pages

1. No repositório, abra **Settings → Pages**.
2. Em **Build and deployment**, escolha **Deploy from a branch**.
3. Selecione a branch **main** e a pasta **/(root)**.
4. Clique em **Save** e aguarde a publicação.

Endereço esperado: https://cauanuser.github.io/convite-cha-bebe/

## Observações

- O projeto é estático: não precisa de servidor ou banco de dados.
- O botão de confirmação abre uma conversa no WhatsApp; ele não armazena respostas em uma lista.
- Use dados fictícios enquanto estiver montando o modelo para demonstração.
