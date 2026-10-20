[English](README.md) · **Español** · [Português](README.pt.md)

# Kit de configuración de Alfred Learning

Prepara tu computadora para la ruta de DevOps y Cloud de [Alfred Learning](https://alfred.nubicode.com)
antes de empezar el curso 1. Un script por sistema instala todo lo que usan los diez cursos, y un
segundo script comprueba que todo funcione.

Los cursos funcionan en tu navegador y puedes terminarlos sin instalar nada: sus ejercicios usan una
terminal integrada en la página. Este kit es para hacer el mismo trabajo en una máquina real, que es
como se ve el trabajo de verdad. Configúralo antes de empezar, o vuelve cuando un curso te dé ganas de
probar algo en serio.

> **Las guías detalladas están en inglés.** Este README está traducido, pero las guías por sistema en
> `docs/`, el material de `materials/` y lo que muestran los scripts siguen en inglés por ahora. Los
> comandos son los mismos en cualquier idioma.

## Inicio rápido

Elige tu sistema. Cada guía explica cada paso, así que también puedes seguirla a mano.

| Sistema | Guía (en inglés) | Un comando |
| --- | --- | --- |
| macOS 13 o más reciente | [docs/macos.md](docs/macos.md) | `./scripts/macos.sh` |
| Ubuntu o Debian | [docs/linux.md](docs/linux.md) | `./scripts/linux.sh` |
| Fedora | [docs/linux.md#fedora](docs/linux.md#fedora) | a mano, con `dnf` |
| Windows 10 (2004+) u 11 | [docs/windows.md](docs/windows.md) | `scripts\windows.ps1`, luego `./scripts/linux.sh` dentro de Ubuntu |

Primero consigue el kit. Si ya tienes Git instalado:

```bash
git clone https://github.com/nubicode-org/alfred-setup.git
cd alfred-setup
```

Si no lo tienes, descarga el ZIP desde el botón verde **Code** en GitHub y descomprímelo. La guía de
tu sistema dice dónde ponerlo.

Luego ejecuta el script de tu sistema. Cada script:

- **muestra lo que va a instalar y te pregunta primero.** `--dry-run` muestra los comandos exactos y no cambia nada.
- **omite lo que ya está instalado**, así que volver a ejecutarlo es seguro y solo completa lo que falta.
- **nunca te pide una cuenta, un token ni una clave de API.** La única contraseña que necesita es la de
  tu propia computadora (`sudo` en Mac y Linux, una ventana de administrador en Windows).

Cuando termine, configura Git y tu clave SSH ([docs/git-and-ssh.md](docs/git-and-ssh.md)) y
comprueba todo:

```bash
./scripts/verify.sh
```

## Qué se instala, y por qué

Cada herramienta de la lista la usa al menos un curso. El **nivel** dice cuándo la necesitas.

- **core**: desde el curso 1. Todos los cursos dan por hecho una terminal, un editor y Git.
- **course**: la usa un curso específico. Si falta, solo importa cuando llegues a ese curso.
- **later**: los temas de nube que vienen después de los primeros diez cursos. No se instalan a menos
  que lo pidas (`--with-cloud`).

Los nombres de los niveles quedan en inglés porque son los que muestra `verify.sh`.

| Herramienta | Nivel | Para qué sirve | Cursos |
| --- | --- | --- | --- |
| Una terminal y un shell (bash o zsh) | core | Donde se ejecuta cada comando de los cursos | Todos |
| Git | core | Control de versiones; cada archivo de práctica vive en un repositorio | Git, todos |
| GitHub CLI (`gh`) | core | Pull requests y repositorios desde la terminal | Git, CI/CD |
| OpenSSH (`ssh`, `ssh-keygen`) | core | La clave que te permite hacer push a GitHub sin contraseña | Entorno local, Git |
| VS Code + [extensiones](docs/vscode.md) | core | El editor que dan por hecho las guías | Todos |
| curl, jq | core | Llamar APIs y leer su JSON | Redes, CI/CD |
| OpenSSL | core | Leer certificados | Redes, Concientización en seguridad |
| Python 3.10+ | course | Scripts para operadores | Programación |
| Go | course | Herramientas pequeñas de un solo archivo | Programación |
| Node.js LTS y npm | course | Las apps de ejemplo que construyen los pipelines | CI/CD, Contenedores |
| dig, nc, traceroute | course | DNS, puertos y rutas | Redes |
| ShellCheck | course | Detectar errores en scripts de shell antes de que se ejecuten | Sistemas operativos, Entorno local |
| Docker, con Compose | course | Construir y ejecutar contenedores | Contenedores, Seguridad |
| kubectl, kind, Helm | course | Un clúster de Kubernetes real en tu laptop | Kubernetes |
| yamllint, actionlint | course | Detectar errores de YAML y de GitHub Actions antes que la CI | CI/CD, Kubernetes |
| pre-commit, gitleaks | course | Hooks que detienen un secreto antes de que se haga commit | Git, Seguridad |
| Trivy | course | Buscar vulnerabilidades conocidas en imágenes | Seguridad, Contenedores |
| AWS CLI | later | El tema de la nube de AWS | Nube de AWS |
| Terraform | later | Infraestructura como código | Infraestructura como código |

Por qué **kind** y no minikube: kind ejecuta un clúster completo como contenedores de Docker, así que
no necesita nada más que el Docker que ya tienes, arranca en menos de un minuto y es lo que usan
muchos pipelines de CI. Si ya usas minikube, quédate con él; el curso de Kubernetes funciona con
cualquiera de los dos.

## Tiempo y espacio

- **Tiempo:** de 20 a 45 minutos, casi todo en descargas. Windows suma un reinicio y unos 10 minutos para WSL.
- **Disco:** unos 8 GB libres (Docker Desktop y sus imágenes son la mayor parte; WSL necesita unos 3 GB más).
- **Memoria:** 8 GB de RAM funcionan; con 16 GB Docker y un clúster de kind van cómodos.
- **Red:** los scripts descargan desde las fuentes oficiales que lista cada guía. Una red de escuela u
  oficina que las bloquee hará que fallen algunos pasos; consulta
  [Solución de problemas](#solución-de-problemas).

## Comprueba tu configuración

`./scripts/verify.sh` no cambia nada. Revisa cada herramienta, muestra su versión y comprueba lo que
no son herramientas: que Docker esté corriendo, que Git sepa tu nombre, que tengas una clave SSH y
que GitHub la acepte.

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

- **PASS**: listo. **WARN**: funciona, pero corrígelo antes del curso que lo necesita (una versión
  vieja, Docker sin iniciar, todavía sin clave SSH). **FAIL**: un curso no va a funcionar hasta que lo
  corrijas. **--**: opcional.
- Termina con estado 1 si algo falló, así que puedes usarlo en tus propios scripts.
- `--offline` omite la comprobación de GitHub, que necesita red.
- En Windows, ejecútalo dentro de Ubuntu: ahí es donde viven las herramientas.

## Material complementario

[materials/](materials/README.md) tiene archivos iniciales para cada curso: un repositorio de práctica
para Git, un Dockerfile y un archivo de compose, manifiestos de Kubernetes para kind, un workflow de
CI, plantillas de runbooks y más. Acompañan a los cursos de la app, no los reemplazan: los cursos
enseñan, y estos te dejan probarlo en tu propia máquina.

## Cómo instalan las cosas los scripts

- **Desde la fuente oficial**, nunca un espejo: Homebrew en macOS; en Linux, el repositorio apt firmado
  de cada proveedor (GitHub, NodeSource, Docker, Kubernetes, Aqua Security, Microsoft, HashiCorp) o la
  página de releases del propio proyecto (Go, kind, Helm, actionlint, gitleaks).
- **Las descargas de releases se comparan con su SHA-256 publicado.** Eso detecta una descarga dañada
  o alterada; no hace que un proyecto sea más confiable de lo que es.
- **Últimas versiones estables.** Los scripts buscan la línea LTS actual de Node.js, las versiones
  estables actuales de Go y Kubernetes, y la última release de cada herramienta. Define `NODE_MAJOR=22`
  (por ejemplo) para elegir tú la línea de Node.js.
- **Tu perfil se edita solo donde una herramienta lo necesita**: en Apple silicon, la única línea que
  Homebrew pide en `~/.zprofile`; en Linux, `pipx ensurepath` para pre-commit. Cada línea se agrega
  una sola vez.
- **No se sube nada y nada se reporta a ningún servidor.** Las únicas llamadas de red son descargas.

## Solución de problemas

Empieza con `./scripts/verify.sh`: cada falla termina con una línea que dice qué hacer. Las guías por
sistema tienen una sección de solución de problemas para lo específico de cada sistema.

**Una herramienta está instalada pero aparece "command not found".** Abre una terminal nueva: una
terminal solo lee `PATH` cuando arranca. verify.sh dice "installed at ... but not on PATH" cuando esa
es la causa. Si una terminal nueva no lo arregla, cierra sesión y vuelve a entrar (Linux), o revisa
que tu perfil de shell tenga la línea que agregó el script (`~/.zprofile` en una Mac).

**Docker: "permission denied ... docker.sock" (Linux).** Te agregaron al grupo `docker`, pero eso solo
aplica en sesiones nuevas. Cierra sesión y vuelve a entrar, o reinicia. (Estar en ese grupo equivale a
tener root en la máquina; es normal en una computadora personal de desarrollo, y es una razón para no
hacerlo en un servidor compartido).

**Docker: "Cannot connect to the Docker daemon".** Docker está instalado pero no está corriendo. Abre
Docker Desktop (macOS, Windows) y espera a que diga que está corriendo, o ejecuta
`sudo systemctl start docker` (Linux).

**"Could not look up the latest release" o HTTP 403 de GitHub.** GitHub permite 60 consultas anónimas
por hora por red, y una red compartida de escuela u oficina puede agotarlas. Espera una hora, o
ejecuta el script desde otra red.

**Las descargas fallan en una red de escuela u oficina.** Algunas redes bloquean los servidores de
paquetes o inspeccionan el tráfico. Prueba en una red de casa o con el hotspot de tu celular, o pide a
los administradores de la red que permitan los dominios que lista la guía de tu sistema.

**apt: "Could not get lock /var/lib/dpkg/lock".** Ubuntu está instalando actualizaciones en segundo
plano. Espera unos minutos y vuelve a ejecutar el script.

**Otra cosa.** Vuelve a ejecutar el script: continúa desde donde se detuvo. Si sigue fallando, abre un
issue con tu sistema, el comando y las últimas 30 líneas de la salida (quita cualquier dato personal).

## Contribuir

Las correcciones y mejoras son bienvenidas; consulta [CONTRIBUTING.md](CONTRIBUTING.md) (en inglés).

## Licencia

[MIT](LICENSE), por [NubiCode](https://nubicode.com).
