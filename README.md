# 📱 Family Finance — Flutter App

Aplicativo mobile do **Family Finance**, um projeto open source para organização financeira pessoal e familiar.

O aplicativo se conecta a um backend FastAPI próprio, que por sua vez utiliza:

- 🔌 **Pluggy**
- 🏦 **MeuPluggy**
- 🏛️ **Open Finance**
- 🗄️ **Supabase / PostgreSQL**
- ☁️ **Render**

A ideia é permitir que qualquer pessoa possa clonar o projeto e montar sua própria instância para uso pessoal ou da família.

---

# ✨ Funcionalidades

O aplicativo possui recursos como:

- 👤 cadastro e login;
- 🔐 autenticação persistente;
- 👆 biometria;
- 🏦 visualização de contas bancárias;
- 💳 cartões de crédito;
- 🔄 movimentações;
- 🟢 PIX;
- 📈 investimentos;
- ✍️ investimentos manuais;
- 📅 planejamento mensal;
- 💵 salário esperado;
- ➕ outros recebimentos esperados;
- 📝 compromissos manuais;
- 🗓️ períodos personalizados para cartões;
- 📌 observações de cartões;
- 👁️ ocultação de valores financeiros;
- 🔌 conexão de instituições pela Pluggy.

---

# 🧱 Arquitetura

```text
┌────────────────────┐
│     📱 Flutter App │
│ Android / iOS      │
└─────────┬──────────┘
          │
          │ HTTPS
          ▼
┌────────────────────┐
│ ⚡ Backend FastAPI │
│ ☁️ Render          │
└─────────┬──────────┘
          │
     ┌────┴─────┐
     ▼          ▼
🗄️ Supabase    🔌 Pluggy
                  │
                  ▼
              🏦 MeuPluggy
                  │
                  ▼
            🏛️ Open Finance
```

> 🔐 O Flutter **não acessa diretamente o PostgreSQL nem utiliza o CLIENT_SECRET da Pluggy**.

Toda comunicação sensível passa pelo backend.

---

# 1. 🧰 Pré-requisitos

Instale:

- ✅ Git
- ✅ Flutter SDK
- ✅ Android Studio
- ✅ Android SDK
- ✅ VS Code ou Android Studio
- ✅ um dispositivo Android ou emulador

Confira sua instalação:

```bash
flutter doctor
```

Resolva os itens obrigatórios indicados antes de continuar.

---

# 2. 📥 Clone o projeto

Faça um fork deste repositório.

Depois:

```bash
git clone SEU_REPOSITORIO
cd app-family-finance
```

Instale as dependências:

```bash
flutter pub get
```

✅ Projeto Flutter preparado.

---

# 3. ⚡ Configure primeiro o backend

Antes de rodar o aplicativo, sua API precisa estar funcionando.

Siga o README do repositório backend para configurar:

```text
🔌 Pluggy
🏦 MeuPluggy
🗄️ Supabase
☁️ Render
⚡ FastAPI
```

No final, você deverá possuir uma URL semelhante a:

```text
https://seu-family-finance.onrender.com
```

Teste:

```text
/health
```

antes de continuar.

---

# 4. 🔗 Configure a URL da API

Abra:

```text
lib/config/api_config.dart
```

Você encontrará algo semelhante a:

```dart
class ApiConfig {
  static const String baseUrl =
      "https://family-finance-qfyu.onrender.com";
}
```

Troque pela URL do seu backend:

```dart
class ApiConfig {
  static const String baseUrl =
      "https://SEU-BACKEND.onrender.com";
}
```

> ⚠️ Essa é uma das alterações obrigatórias para quem fizer fork do projeto.

---

# 5. ▶️ Rodando localmente

Com um emulador ou celular conectado:

```bash
flutter devices
```

Depois:

```bash
flutter run
```

Caso existam vários dispositivos:

```bash
flutter run -d ID_DO_DISPOSITIVO
```

---

# 6. 🖥️ Backend local

Se quiser utilizar o FastAPI localmente em vez do Render:

### 🤖 Android Emulator

Use:

```dart
static const String baseUrl =
    "http://10.0.2.2:8000";
```

### 🌐 Flutter Desktop / Chrome

Normalmente:

```dart
static const String baseUrl =
    "http://127.0.0.1:8000";
```

### 📱 Celular físico

O celular precisa alcançar o computador na rede local.

Exemplo:

```dart
static const String baseUrl =
    "http://192.168.1.50:8000";
```

O endereço dependerá do IP local do seu computador.

---

# 7. 🏦 MeuPluggy

Para utilizar dados financeiros reais de forma pessoal, crie uma conta no MeuPluggy.

No MeuPluggy:

1. escolha **Conectar Conta**;
2. encontre sua instituição;
3. siga o fluxo do Open Finance;
4. autorize o compartilhamento;
5. repita para os bancos desejados.

Exemplo:

```text
🏦 MeuPluggy
├── Banco A
├── Banco B
└── Banco C
```

Depois, no Dashboard da Pluggy, sua aplicação de desenvolvimento deverá permitir o conector:

```text
MeuPluggy
```

---

# 8. 🔌 Dashboard Pluggy

No Dashboard de desenvolvedores da Pluggy:

1. ➕ crie sua Application em Development;
2. 🏦 configure o conector MeuPluggy;
3. 📋 copie o `CLIENT_ID`;
4. 🔐 copie o `CLIENT_SECRET`;
5. ⚡ coloque essas duas informações **somente no backend**.

Nunca faça isso no Flutter:

```dart
const clientSecret = "...";
```

> 🚨 O aplicativo deve receber somente um **Connect Token temporário** criado pelo backend.

---

# 9. 🔗 Conectando uma instituição pelo aplicativo

Depois de criar uma conta no Family Finance:

1. abra a área de instituições;
2. toque em **Conectar instituição**;
3. o aplicativo solicita um Connect Token ao backend;
4. o Pluggy Connect é aberto;
5. selecione o **MeuPluggy**;
6. faça a autorização;
7. escolha a conexão bancária desejada;
8. aguarde a sincronização.

### 🔄 Fluxo

```text
📱 Flutter
   │
   ▼
⚡ Backend
   │
   ▼
🎫 Pluggy Connect Token
   │
   ▼
🌐 Flutter WebView
   │
   ▼
🏦 MeuPluggy
   │
   ▼
🆔 Item ID
   │
   ▼
⚡ Backend
   │
   ▼
💾 Dados sincronizados
```

---

# 10. 💡 Por que utilizar MeuPluggy?

O objetivo do MeuPluggy é permitir que o próprio usuário controle suas conexões e consentimentos financeiros.

Isso é especialmente interessante para projetos pessoais porque permite separar:

```text
🏦 Consentimento bancário
        ↓
MeuPluggy
        ↓
🔌 Aplicação do desenvolvedor
        ↓
💰 Family Finance
```

Assim, o Family Finance não precisa implementar diretamente o fluxo de autenticação específico de cada instituição.

---

# 11. 📦 Dados locais

Algumas informações auxiliares são armazenadas localmente no aparelho através de:

```text
FlutterSecureStorage
```

Por exemplo:

- 🔑 token de autenticação;
- ⚙️ preferências locais;
- 📅 alguns dados de planejamento;
- 🏷️ aliases;
- 📝 observações auxiliares.

Informações financeiras sincronizadas ficam sob responsabilidade do backend/banco configurado pelo projeto.

---

# 12. 👁️ Privacidade

O aplicativo possui opção para ocultar valores financeiros.

Além disso, utiliza autenticação local/biometria em dispositivos compatíveis.

> 🔐 Mesmo assim, este é um projeto open source e cada pessoa responsável por seu próprio fork deve revisar os requisitos de segurança antes de distribuir o aplicativo para terceiros.

---

# 13. 📦 Gerando APK

Para gerar uma versão Android:

```bash
flutter build apk --release
```

O APK normalmente será criado em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Para testes rápidos também é possível:

```bash
flutter build apk --debug
```

🎉 O aplicativo estará pronto para instalação.

---

# 14. 📲 Instalação no Android

Copie o APK para o celular e instale.

Dependendo do Android, será necessário permitir:

```text
Instalar apps desconhecidos
```

para o aplicativo utilizado na instalação.

---

# 15. ⚠️ Atenção antes de distribuir

O projeto original ainda deve ser personalizado por quem fizer o fork.

Revise principalmente:

```text
🏷️ Nome do aplicativo
🎨 Ícone
🤖 applicationId Android
🍎 Bundle Identifier iOS
🔗 URL do backend
🔐 assinatura Android
📜 política de privacidade
```

> 🚨 Não publique um aplicativo na Play Store utilizando configuração de assinatura de desenvolvimento/debug.

---

# 16. 📂 Estrutura principal

```text
app-family-finance/
│
├── 🤖 android/
├── 🍎 ios/
├── 🎨 assets/
│
├── 📁 lib/
│   ├── config/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── pubspec.yaml
└── README.md
```

---

# 17. 📚 Dependências principais

O projeto utiliza Flutter/Dart e bibliotecas como:

```text
http
flutter_secure_storage
provider
webview_flutter
intl
local_auth
```

O Pluggy Connect é aberto dentro do fluxo mobile através de WebView.

---

# 18. 🔄 Atualizando seu fork

Para receber atualizações do projeto original, configure o repositório original como `upstream`.

Exemplo:

```bash
git remote add upstream REPOSITORIO_ORIGINAL
```

Depois:

```bash
git fetch upstream
git merge upstream/main
```

Resolva eventuais conflitos antes de compilar novamente.

---

# 19. 🆓 Stack gratuita sugerida

Para um projeto pessoal/familiar:

```text
🐙 GitHub
   │
   ├── ⚡ Backend FastAPI
   │        │
   │        ├── ☁️ Render Free
   │        ├── 🗄️ Supabase Free
   │        └── 🔌 Pluggy / MeuPluggy
   │
   └── 📱 Flutter
            │
            └── 📦 APK instalado nos celulares
```

Não é necessário manter um servidor dentro de casa.

O celular acessa diretamente a URL pública do backend.

---

# 20. ⚠️ Observação sobre serviços gratuitos

Planos gratuitos podem possuir:

- 📊 limites de uso;
- 🔢 limites de requisições;
- 💤 suspensão por inatividade;
- ⏳ tempo maior no primeiro acesso;
- 🔄 mudanças futuras de política.

Por isso, consulte sempre a documentação atual dos serviços utilizados.

O projeto é adequado principalmente para:

```text
👤 uso pessoal
👨‍👩‍👧‍👦 uso familiar
📚 aprendizado
🛠️ hobby
🧪 prototipação
```

Para uso comercial, revise a infraestrutura e os planos dos provedores.

---

# 21. 🔒 Segurança

Nunca coloque no Flutter:

```text
PLUGGY_CLIENT_SECRET
senha do Supabase
SECRET_KEY do backend
credenciais bancárias
```

Essas informações pertencem exclusivamente ao backend.

O aplicativo deve conhecer apenas:

```text
🔗 URL pública do backend
🎫 token JWT do usuário
🔌 Connect Token temporário
```

---

# 22. 🚀 Fluxo completo de instalação

Para uma nova família replicar o projeto:

```text
1.  🐙 Fork backend
        ↓
2.  🗄️ Criar Supabase
        ↓
3.  🏦 Criar MeuPluggy
        ↓
4.  🔗 Conectar bancos ao MeuPluggy
        ↓
5.  🔌 Criar Pluggy Dashboard
        ↓
6.  🧪 Criar Application Development
        ↓
7.  ✅ Habilitar MeuPluggy
        ↓
8.  🔐 Configurar CLIENT_ID / CLIENT_SECRET
        ↓
9.  ☁️ Deploy backend no Render
        ↓
10. ❤️ Testar /health
        ↓
11. 🐙 Fork Flutter
        ↓
12. 🔗 Alterar ApiConfig.baseUrl
        ↓
13. 📦 flutter pub get
        ↓
14. ▶️ flutter run
        ↓
15. 👤 Criar usuário
        ↓
16. 🏦 Conectar MeuPluggy
        ↓
17. 🔄 Sincronizar contas
        ↓
18. 📱 Gerar APK
```

---

# 23. 🤝 Contribuições

Sugestões, correções e melhorias são bem-vindas.

Antes de abrir um Pull Request:

```bash
flutter analyze
flutter test
```

e teste as principais telas afetadas.

---

## ⚖️ Aviso

Este é um projeto independente.

Não possui vínculo oficial com Pluggy, MeuPluggy, Supabase, Render ou instituições financeiras exibidas no aplicativo.

O uso, armazenamento e compartilhamento de dados financeiros são responsabilidade de quem executar sua própria instância.
