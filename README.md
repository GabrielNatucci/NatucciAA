# NatucciAA

NatucciAA é um sistema de painel/infotainment automotivo desenvolvido inteiramente na linguagem **Zig**. O projeto utiliza a biblioteca **SDL2** para renderização gráfica e interface com o usuário, e integra-se com o sistema via **D-Bus** para gerenciamento de conexões e reprodução de mídia via **Bluetooth**.

A interface é renderizada em uma resolução de 1280x720 e é construída utilizando um sistema de Cenas (`HomeScene`, `BluetoothScene`, `MusicScene`, etc.).

## 🚀 Funcionalidades

- **Gerenciador de Cenas:** Navegação fluida entre as diferentes telas do sistema.
- **Conectividade Bluetooth:** Integração via D-Bus para buscar e gerenciar dispositivos Bluetooth.
- **Reprodutor de Música:** Controle de mídia (Play, Pause, Next, Previous) com metadados (TrackInfo).
- **Interface Gráfica Baseada em SDL2:** Utiliza componentes customizados de Texto, Imagens e Loading.

## 🛠️ Tecnologias e Dependências

Este projeto é desenvolvido em [Zig](https://ziglang.org/) e possui dependências de bibliotecas de sistema C. Certifique-se de que os pacotes de desenvolvimento das seguintes bibliotecas estejam instalados no seu sistema operacional Linux:

- **Zig Compiler** (versão suportada pelo `build.zig` do projeto)
- **SDL2** (`libsdl2-dev`)
- **SDL2_image** (`libsdl2-image-dev`)
- **SDL2_mixer** (`libsdl2-mixer-dev`)
- **SDL2_ttf** (`libsdl2-ttf-dev`)
- **D-Bus** (`libdbus-1-dev`)
- **libc** padrão

No Ubuntu/Debian, você pode instalar as dependências de C com:
```bash
sudo apt install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libdbus-1-dev
```

## ⚙️ Como Compilar e Rodar

O projeto utiliza o sistema de build nativo do Zig.

Para compilar e executar o projeto diretamente, use o comando:

```bash
zig build run
```

Para apenas compilar o executável (ele será gerado na pasta `zig-out/bin/`):

```bash
zig build
```

*(O executável precisará estar no mesmo diretório em que a pasta `res/` está acessível, dependendo de como as rotas estáticas estão configuradas no código).*

## 📂 Estrutura do Projeto

- `src/main.zig`: Ponto de entrada da aplicação, inicializa o SDL2, D-Bus, Bluetooth e o SceneManager.
- `src/core/`: Lógica central, incluindo o gerenciamento de tela e as implementações específicas (D-Bus, Bluetooth).
- `src/core/scenes/`: Contém as telas (Home, Música, Configuração e Bluetooth) e os componentes visuais (`Text`, `Image`, `Loading`).
- `res/`: Recursos estáticos do projeto, como fontes (`.ttf`) e imagens (ícones, fundos, etc).
- `build.zig`: Script de compilação da aplicação, cuidando do link com o SDL2 e D-Bus.

## 💡 Observações

- A interface está travada na resolução de 1280x720.
- O sistema calcula e exibe no console a contagem de FPS a cada segundo.
- Certifique-se de que o serviço D-Bus e o Bluetoothd estejam rodando no seu Linux para que o `BluetoothManager` funcione corretamente.
