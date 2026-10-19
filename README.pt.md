[English](README.md) · [Español](README.es.md) · **Português**

# Kit de configuração do Alfred Learning

Deixe seu computador pronto para a trilha de DevOps e Cloud do
[Alfred Learning](https://alfred.nubicode.com) antes de começar o curso 1. Um script por sistema
instala tudo o que os dez cursos usam, e um segundo script confere se tudo funciona.

Os cursos rodam no seu navegador e podem ser concluídos sem instalar nada: os exercícios usam um
terminal embutido na página. Este kit é para fazer o mesmo trabalho em uma máquina de verdade, que é
como o trabalho realmente é. Configure antes de começar, ou volte quando um curso der vontade de
experimentar algo de verdade.

> **Os guias detalhados estão em inglês.** Este README está traduzido, mas os guias por sistema em
> `docs/`, o material em `materials/` e o que os scripts mostram continuam em inglês por enquanto. Os
> comandos são os mesmos em qualquer idioma.

## Início rápido

Escolha seu sistema. Cada guia explica cada passo, então você também pode segui-lo à mão.

| Sistema | Guia (em inglês) | Um comando |
| --- | --- | --- |
| macOS 13 ou mais recente | [docs/macos.md](docs/macos.md) | `./scripts/macos.sh` |
| Ubuntu ou Debian | [docs/linux.md](docs/linux.md) | `./scripts/linux.sh` |
| Fedora | [docs/linux.md#fedora](docs/linux.md#fedora) | à mão, com `dnf` |
| Windows 10 (2004+) ou 11 | [docs/windows.md](docs/windows.md) | `scripts\windows.ps1`, depois `./scripts/linux.sh` dentro do Ubuntu |

Primeiro, baixe o kit. Se o Git já estiver instalado:

```bash
git clone https://github.com/nubicode-org/alfred-setup.git
cd alfred-setup
```

Se não estiver, baixe o ZIP pelo botão verde **Code** no GitHub e descompacte. O guia do seu sistema
diz onde colocá-lo.

Depois, execute o script do seu sistema. Todo script:

- **mostra o que vai instalar e pergunta antes.** `--dry-run` mostra os comandos exatos e não altera nada.
- **pula o que já está instalado**, então executá-lo de novo é seguro e só completa o que falta.
- **nunca pede uma conta, um token ou uma chave de API.** A única senha de que ele precisa é a do seu
  próprio computador (`sudo` no Mac e no Linux, uma janela de administrador no Windows).

Quando terminar, configure o Git e sua chave SSH ([docs/git-and-ssh.md](docs/git-and-ssh.md)) e
confira tudo:

```bash
./scripts/verify.sh
```

## O que é instalado, e por quê

Cada ferramenta abaixo é usada por pelo menos um curso. O **nível** diz quando você vai precisar dela.

- **core**: desde o curso 1. Todo curso pressupõe um terminal, um editor e o Git.
- **course**: um curso específico usa. Se faltar, só importa quando você chegar a esse curso.
- **later**: os temas de nuvem depois dos primeiros dez cursos. Não são instalados a menos que você
  peça (`--with-cloud`).

Os nomes dos níveis ficam em inglês porque são os que o `verify.sh` mostra.

| Ferramenta | Nível | Para que serve | Cursos |
| --- | --- | --- | --- |
| Um terminal e um shell (bash ou zsh) | core | Onde todo comando dos cursos é executado | Todos |
| Git | core | Controle de versão; todo arquivo de prática fica em um repositório | Git, todos |
| GitHub CLI (`gh`) | core | Pull requests e repositórios pelo terminal | Git, CI/CD |
| OpenSSH (`ssh`, `ssh-keygen`) | core | A chave que permite fazer push no GitHub sem senha | Ambiente local, Git |
| VS Code + [extensões](docs/vscode.md) | core | O editor que os guias pressupõem | Todos |
| curl, jq | core | Chamar APIs e ler o JSON delas | Redes, CI/CD |
| OpenSSL | core | Ler certificados | Redes, Conscientização em segurança |
| Python 3.10+ | course | Scripts para operadores | Programação |
| Go | course | Ferramentas pequenas de um único arquivo | Programação |
| Node.js LTS e npm | course | Os apps de exemplo que os pipelines constroem | CI/CD, Contêineres |
| dig, nc, traceroute | course | DNS, portas e rotas | Redes |
| ShellCheck | course | Pegar erros em scripts de shell antes que rodem | Sistemas operacionais, Ambiente local |
| Docker, com Compose | course | Construir e executar contêineres | Contêineres, Segurança |
| kubectl, kind, Helm | course | Um cluster Kubernetes de verdade no seu notebook | Kubernetes |
| yamllint, actionlint | course | Pegar erros de YAML e de GitHub Actions antes da CI | CI/CD, Kubernetes |
| pre-commit, gitleaks | course | Hooks que barram um segredo antes do commit | Git, Segurança |
| Trivy | course | Procurar vulnerabilidades conhecidas em imagens | Segurança, Contêineres |
| AWS CLI | later | O tema de nuvem AWS | Nuvem AWS |
| Terraform | later | Infraestrutura como código | Infraestrutura como código |

Por que **kind** e não minikube: o kind roda um cluster inteiro como contêineres Docker, então não
precisa de nada além do Docker que você já tem, sobe em menos de um minuto e é o que muitos pipelines
de CI usam. Se você já usa minikube, pode continuar com ele; o curso de Kubernetes funciona com
qualquer um dos dois.

## Tempo e espaço

- **Tempo:** de 20 a 45 minutos, quase tudo em downloads. O Windows soma uma reinicialização e cerca de 10 minutos para o WSL.
- **Disco:** cerca de 8 GB livres (o Docker Desktop e suas imagens são a maior parte; o WSL precisa de uns 3 GB a mais).
- **Memória:** 8 GB de RAM funcionam; com 16 GB o Docker e um cluster kind ficam confortáveis.
- **Rede:** os scripts baixam das fontes oficiais listadas em cada guia. Uma rede de escola ou
  escritório que as bloqueie vai fazer alguns passos falharem; veja
  [Solução de problemas](#solução-de-problemas).

## Confira sua configuração

`./scripts/verify.sh` não altera nada. Ele confere cada ferramenta, mostra sua versão e verifica o
que não é ferramenta: se o Docker está rodando, se o Git sabe seu nome, se você tem uma chave SSH e
se o GitHub a aceita.

```text
  CHECK           TIER    STATE VERSION / DETAIL
  --------------- ------- ----- ----------------
  git             core    PASS  2.51.0
  python3         course  PASS  3.12.3
  kind            course  FAIL  missing (Kubernetes (a local cluster))
  terraform       later   --    not installed (Infrastructure as Code, optional for now)
  ...
  docker engine   course  PASS  running
  git identity    setup   PASS  Ada Lovelace <ada@example.com>
  github ssh      setup   PASS  signed in as ada

1 check(s) failed, 0 warning(s). What to do:
  - kind is missing. Re-run the setup script for your system, or install it by hand: docs/linux.md
```

- **PASS**: pronto. **WARN**: funciona, mas corrija antes do curso que precisa disso (uma versão
  antiga, o Docker não iniciado, ainda sem chave SSH). **FAIL**: um curso não vai funcionar até você
  corrigir. **--**: opcional.
- Ele sai com status 1 se algo falhou, então você pode usá-lo nos seus próprios scripts.
- `--offline` pula a verificação do GitHub, que precisa de rede.
- No Windows, execute dentro do Ubuntu: é lá que as ferramentas ficam.

## Material complementar

[materials/](materials/README.md) tem arquivos iniciais para cada curso: um repositório de prática
para Git, um Dockerfile e um arquivo compose, manifestos Kubernetes para o kind, um workflow de CI,
modelos de runbook e mais. Eles acompanham os cursos do app, não os substituem: os cursos ensinam, e
estes deixam você experimentar na sua própria máquina.

## Como os scripts instalam as coisas

- **Da fonte oficial**, nunca de um espelho: Homebrew no macOS; no Linux, o repositório apt assinado
  de cada fornecedor (GitHub, NodeSource, Docker, Kubernetes, Aqua Security, Microsoft, HashiCorp) ou a
  página de releases do próprio projeto (Go, kind, Helm, actionlint, gitleaks).
- **Os downloads de releases são conferidos com o SHA-256 publicado.** Isso detecta um download
  corrompido ou alterado; não torna um projeto mais confiável do que ele é.
- **Últimas versões estáveis.** Os scripts buscam a linha LTS atual do Node.js, as versões estáveis
  atuais do Go e do Kubernetes, e a última release de cada ferramenta. Defina `NODE_MAJOR=22` (por
  exemplo) para escolher você mesmo a linha do Node.js.
- **Seu perfil só é editado onde uma ferramenta precisa**: no Apple silicon, a única linha que o
  Homebrew pede em `~/.zprofile`; no Linux, `pipx ensurepath` para o pre-commit. Cada linha é
  adicionada uma única vez.
- **Nada é enviado e nada se comunica com servidor nenhum.** As únicas chamadas de rede são downloads.

## Solução de problemas

Comece com `./scripts/verify.sh`: cada falha termina com uma linha dizendo o que fazer. Os guias por
sistema têm uma seção de solução de problemas para o que é específico de cada sistema.

**Uma ferramenta está instalada, mas aparece "command not found".** Abra um terminal novo: um terminal
só lê o `PATH` quando inicia. O verify.sh diz "installed at ... but not on PATH" quando essa é a
causa. Se um terminal novo não resolver, saia da sessão e entre de novo (Linux), ou confira se o seu
perfil de shell tem a linha que o script adicionou (`~/.zprofile` em um Mac).

**Docker: "permission denied ... docker.sock" (Linux).** Seu usuário foi adicionado ao grupo `docker`,
mas isso só vale para novas sessões. Saia da sessão e entre de novo, ou reinicie. (Estar nesse grupo
equivale a ter root na máquina; isso é normal em um computador pessoal de desenvolvimento, e é um
motivo para não fazer isso em um servidor compartilhado.)

**Docker: "Cannot connect to the Docker daemon".** O Docker está instalado, mas não está rodando. Abra
o Docker Desktop (macOS, Windows) e espere ele dizer que está rodando, ou execute
`sudo systemctl start docker` (Linux).

**"Could not look up the latest release" ou HTTP 403 do GitHub.** O GitHub permite 60 consultas
anônimas por hora por rede, e uma rede compartilhada de escola ou escritório pode esgotá-las. Espere
uma hora, ou execute o script de outra rede.

**Os downloads falham em uma rede de escola ou escritório.** Algumas redes bloqueiam servidores de
pacotes ou inspecionam o tráfego. Tente uma rede doméstica ou compartilhe a internet do celular, ou peça aos
administradores da rede que liberem os domínios listados no guia do seu sistema.

**apt: "Could not get lock /var/lib/dpkg/lock".** O Ubuntu está instalando atualizações em segundo
plano. Espere alguns minutos e execute o script de novo.

**Outra coisa.** Execute o script de novo: ele continua de onde parou. Se ainda falhar, abra uma issue
com seu sistema, o comando e as últimas 30 linhas da saída (remova qualquer dado pessoal).

## Como contribuir

Correções e melhorias são bem-vindas; veja [CONTRIBUTING.md](CONTRIBUTING.md) (em inglês).

## Licença

[MIT](LICENSE), por [NubiCode](https://nubicode.com).
