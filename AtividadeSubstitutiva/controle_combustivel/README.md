# Controle de combustível

Aplicativo Flutter para cadastrar um veículo, registrar abastecimentos
e acompanhar gastos, consumo e custo por quilômetro.

Projeto desenvolvido para a atividade de Controle de Gastos com Combustível.

## Funcionalidades

- Cadastro de um veículo por vez.
- Consulta de marcas e modelos de carros em uma API pública.
- Modelos filtrados pela marca selecionada.
- Cadastro de ano e cilindrada em cm³.
- Exclusão do veículo com confirmação e remoção dos abastecimentos associados.
- Registro de etanol, gasolina ou diesel.
- Registro de preço por litro, quilometragem, litros, data e horário.
- Cálculo automático do valor total.
- Persistência local em SQLite.
- Histórico de abastecimentos.
- Dashboard com total gasto e gráficos de:
  - Valor por abastecimento.
  - Consumo em km/L.
  - Custo por quilômetro em R$/km.
- Validação da sequência de quilometragem e das datas dos registros.

## Requisitos para execução

- Flutter instalado e configurado, com Dart incluído.
- Android SDK e ferramentas de compilação configurados.
- Celular Android com depuração USB autorizada ou emulador Android.
- Internet para consultar marcas e modelos.

Esta versão está configurada para execução no Android.
Windows e navegador exigem configuração adicional do banco de dados.

## Como executar

Clone o repositório e abra um terminal na pasta que contém o pubspec.yaml.

Instale as dependências:

```bash
flutter pub get
```

Confira o ambiente e os dispositivos:

```bash
flutter doctor
flutter devices
```

Execute no Android, substituindo o identificador:

```bash
flutter run -d ID_DO_DISPOSITIVO
```

## API utilizada

API FIPE da Parallelum, um serviço de terceiros para consulta de veículos.

Documentação:
https://deividfortuna.github.io/fipe/

Endpoints utilizados:

- Marcas:
  https://parallelum.com.br/fipe/api/v1/carros/marcas
- Modelos por marca:
  https://parallelum.com.br/fipe/api/v1/carros/marcas/{codigoMarca}/modelos

Ano e cilindrada são preenchidos manualmente.
A consulta de marcas e modelos depende de conexão e disponibilidade da API.

## Bibliotecas

| Biblioteca | Finalidade |
|---|---|
| http | Requisições à API |
| sqflite | Persistência local com SQLite |
| path | Caminho do arquivo do banco |
| fl_chart | Gráficos do dashboard |
| intl | Formatação de datas, números e valores |
| flutter_test | Testes automatizados |

As versões utilizadas estão registradas em pubspec.yaml e pubspec.lock.

## Cálculos

Todos os registros representam abastecimentos que completam o tanque.

- Valor total = preço por litro × litros abastecidos.
- Distância = quilometragem atual − quilometragem anterior.
- Consumo = distância ÷ litros do abastecimento atual.
- Custo por km = valor total atual ÷ distância.

Os registros são comparados em ordem cronológica.
O primeiro abastecimento serve como referência e não apresenta
indicadores de consumo ou custo por quilômetro.

Exemplo:

- Primeiro abastecimento: 10.000 km.
- Segundo abastecimento: 10.400 km, 32 litros e R$ 6,00 por litro.
- Distância: 400 km.
- Valor total: R$ 192,00.
- Consumo: 12,50 km/L.
- Custo por km: R$ 0,48/km.

## Organização

```text
lib/
├── main.dart
├── models/
├── services/
├── repositories/
├── controllers/
├── pages/
└── widgets/
```

Os modelos representam os dados. Os serviços acessam a API e o banco.
Os repositórios consultam e gravam os registros.
As páginas implementam a interface e a navegação.

## Verificação

Análise estática:

```bash
flutter analyze
```

Testes automatizados:

```bash
flutter test
```

Os testes verificam cálculos, intervalos inválidos e conversão
dos abastecimentos para armazenamento.

## Capturas de tela

### Cadastro do veículo
![Cadastro do veículo](docs/screenshots/cadastro.png)

### Veículo cadastrado
![Veículo cadastrado](docs/screenshots/veiculo.png)

### Novo abastecimento
![Registro de abastecimento](docs/screenshots/abastecimento.png)

### Histórico
![Histórico](docs/screenshots/historico.png)

### Consumo
![Gráfico de consumo](docs/screenshots/dashboard-consumo.png)

### Custo por quilômetro
![Gráfico de custo](docs/screenshots/dashboard-custo.png)

## Armazenamento

Os dados ficam no dispositivo e permanecem após fechar o aplicativo.
Não há sincronização em nuvem. Limpar os dados do aplicativo ou
desinstalá-lo remove os registros locais.