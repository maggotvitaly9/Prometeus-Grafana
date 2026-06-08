# Развертывание и настройка современной системы мониторинга Prometheus и Grafana
Данный проект представляет собой готовую инфраструктуру для мониторинга серверов и Docker-контейнеров. 

## Технологический стек
* **Prometheus (v2.53.0)** — сбор и хранение метрик.
* **Grafana (v11.1.0)** — визуализация данных и управление дашбордами.
* **Node Exporter (v1.8.2)** — сбор аппаратных метрик хоста (CPU, RAM, Disk). 
* **cAdvisor (v0.49.1)** — сбор метрик потребления ресурсов Docker-контейнерами.

## Структура репозитория

```text
├── config/
│   ├── grafana/                	# Конфигурация Grafana
│	│	├──	dashboards				# Путь хранения дашбордов
│	│	└──	provisioning
│	│		├──	dashboards
│	│		│	└── dashboards.yml	# Конфигурация дашбордов
│	│		└──	datasources
│	│			└──	prometheus.yml	# Конфигурация подключения базы данны к Grafana
│   └── prometheus/             	# Конфигурация Prometheus
│		└──	prometheus.yml.template	# Шаблон конфигурации Prometheus			
├── deploy/
│   └── docker-compose.yml      	# Основной манифест Docker Compose
├── scripts/
│   └── bootstrap.sh            	# Скрипт автоматической установки
├── .env.example                    # Шаблон файла переменных окружения (основной файл создается скриптом)
├── README.md                   	# Документация проекта
└── LICENSE                   		# Файл лицензии открытого ПО
```

## Разработчики проекта

| Участник | Роль | Зона ответственности | 
| :--- | :--- | :--- | 
| Попов В.Д. | DevOps/IaC Engineer, Observability and Security Engineer | Docker Compose, installer, Prometheus, Grafana, cAdvisor, Node Exporter| 
| Кишкан А.А. | System Administrator / SRE | Разворачивание на VM (Ubuntu 25.04). Эксплуатационные процедуры и проверка доступности | 
| Рыкалов М.Ю. | Documentation and QA Engineer | README, сценарий демонстрации, чек-листы, презентационные материалы, контроль соответствия критериям | 

## Требования (Prerequisites)
Перед запуском убедитесь, что на сервере установлены:
* Docker
* Docker Compose

Так же необходимо добавить пользователя, от лица которого происходит установка, в группу docker
```bash
sudo usermod -aG docker $USER
```

Развертывание системы полностью автоматизировано с помощью bash-скрипта. Скрипт самостоятельно создаст файл переменных окружения `.env` и запустит контейнеры.

Выполните в корневой директории проекта:
```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```
В процессе установки скрипт запросит у пользователя некоторые данные.

## Доступ к сервисам

После успешного запуска сервисы будут доступны по следующим адресам (где `IP` — адрес вашего сервера):

| Сервис | Адрес | Логин | Примечание |
| :--- | :--- | :--- | :--- |
| **Grafana** | `http://IP:3000` | Заданный логин | Пароль задается при установке |
| **Prometheus** | `http://IP:9090` | - | Внутренний интерфейс базы данных |

## Обязательные команды управления

Так как конфигурация Docker Compose (`deploy/docker-compose.yml`) и файл переменных окружения (`.env`) разнесены по разным директориям, для управления жизненным циклом проекта необходимо **находиться в корневой папке проекта** и явно указывать пути.

**Запуск инфраструктуры в фоновом режиме:**
```bash
docker compose --env-file .env -f deploy/docker-compose.yml up -d
```

**Остановка всех сервисов (без удаления данных):**
```bash
docker compose --env-file .env -f deploy/docker-compose.yml down
```

**Полная остановка с удалением всех данных (Hard Reset):**
Внимание! Эта команда удалит все собранные метрики и пользовательские настройки Grafana (очистит volumes).
```bash
docker compose --env-file .env -f deploy/docker-compose.yml down -v
```

**Перезагрузка конфигурации (при изменении yml-файлов):**
```bash
docker compose --env-file .env -f deploy/docker-compose.yml up -d --force-recreate
```

**Просмотр логов в реальном времени:**
Для всех сервисов сразу:
```bash
docker compose --env-file .env -f deploy/docker-compose.yml logs -f
```
Для конкретного сервиса (например, grafana):
```bash
docker compose --env-file .env -f deploy/docker-compose.yml logs -f grafana
```

## Источники и полезные материалы

При реализации данного проекта использовались следующие официальные источники, документация и материалы сообщества:

### Официальная документация (Движки)
* [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/) — основное руководство по настройке архитектуры сбора метрик, синтаксису конфигурационных файлов и работе с TSDB.
* [Grafana Provisioning Guide](https://grafana.com/docs/grafana/latest/administration/provisioning/) — руководство по автоматическому развертыванию (IaC) источников данных (Data Sources) и дашбордов без использования веб-интерфейса.
* [Docker Compose Specification](https://docs.docker.com/reference/compose-file/) — спецификация манифестов Docker Compose для настройки сетевой связности и управления пространствами имен хоста.

### Экспортеры 
* [Node Exporter GitHub Repository](https://github.com/prometheus/node_exporter) — официальный репозиторий агента.
* [cAdvisor GitHub Repository](https://github.com/google/cadvisor) — официальный репозиторий анализатора контейнеров от Google.


### Каталог дашбордов Grafana Labs
* [Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/) — универсальный дашборд для аппаратного мониторинга Linux-систем.
* [Docker Container & Host Metrics](https://grafana.com/grafana/dashboards/10619-docker-host-container-overview/) —  дашборд для мониторинга контейнерной инфраструктуры через cAdvisor.