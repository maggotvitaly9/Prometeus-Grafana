#!/bin/bash
# @file bootstrap.sh
# @brief Скрипт первичной подготовки ОС и инициализации среды мониторинга.
# @author Команда проекта
# @date 2026-06-07
# @version 1.2.0
#
# @details
# Сценарий автоматизирует генерацию .env, шаблонизацию конфигураций
# через envsubst, выпуск самоподписанных TLS сертификатов, загрузку 
# дашбордов и старт контейнерной фабрики.
#
# @license GNU GPLv3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
cd "${PROJECT_ROOT}"

echo "==================================================="
echo "  Инициализация среды мониторинга (IaC Mode)"
echo "==================================================="

# 1. Сбор данных у пользователя
read -p "Укажите пароль администратора Grafana: " INPUT_GF_PASS
read -p "Укажите пароль для Node Exporter: " INPUT_NODE_PASS
read -p "Укажите срок хранения метрик (например, 15d): " INPUT_RETENTION

echo ""
echo "Выберите дашборды для автоматической загрузки:"
echo "  1) Node Exporter Full (Метрики Linux-хоста)"
echo "  2) cAdvisor Dashboard (Метрики Docker-контейнеров)"
echo "  3) Загрузить оба дашборда"
read -p "Ваш выбор (1-3): " DASHBOARD_CHOICE

# 2. Формирование локального .env файла
echo "LOG: Генерация .env файла..."
cat << EOF > .env
GF_SECURITY_ADMIN_PASSWORD=${INPUT_GF_PASS}
NODE_EXPORTER_PASSWORD=${INPUT_NODE_PASS}
PROMETHEUS_RETENTION=${INPUT_RETENTION}
EOF

export $(grep -v '^#' .env | xargs)

# 3. Декларативная шаблонизация
echo "LOG: Шаблонизация конфигураций через envsubst..."
envsubst < config/prometheus/prometheus.yml.template > config/prometheus/prometheus.yml

# 4. Автоматическая генерация TLS-сертификатов
echo "LOG: Проверка TLS-сертификатов для Node Exporter..."
mkdir -p certs/node_exporter

if [ ! -f "certs/node_exporter/cert.pem" ] || [ ! -f "certs/node_exporter/key.pem" ]; then
    echo "LOG: Сертификаты не найдены. Генерирую новые самоподписанные ключи..."
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -keyout certs/node_exporter/key.pem \
        -out certs/node_exporter/cert.pem \
        -subj "/C=RU/ST=State/L=City/O=Organization/CN=localhost" 2>/dev/null
    echo "SUCCESS: Ключи успешно созданы в certs/node_exporter/"
else
    echo "LOG: Сертификаты уже существуют."
fi

# 5. 
echo "LOG: Проверка наличия утилиты htpasswd..."
if ! command -v htpasswd &> /dev/null; then
    echo "LOG: Утилита htpasswd не найдена. Устанавливаю пакет apache2-utils..."
    sudo apt-get update -qq && sudo apt-get install -y apache2-utils -qq
fi

echo "LOG: Генерация web-config.yml для Node Exporter..."
mkdir -p config/node_exporter

# bcrypt-хэш (-B) пароля
HASHED_PASSWORD=$(htpasswd -nbB admin "${INPUT_NODE_PASS}" | cut -d ":" -f 2)

# Создаем файл настроек с подставленным хэшем
cat << EOF > config/node_exporter/web-config.yml
tls_server_config:
  cert_file: /etc/certs/cert.pem
  key_file: /etc/certs/key.pem

basic_auth_users:
  admin: '${HASHED_PASSWORD}'
EOF
echo "SUCCESS: web-config.yml успешно сгенерирован!"

# 6. Загрузка дашбордов Grafana
echo "LOG: Подготовка каталога дашбордов..."
mkdir -p config/grafana/dashboards
rm -f config/grafana/dashboards/*.json

if [[ "$DASHBOARD_CHOICE" == "1" || "$DASHBOARD_CHOICE" == "3" ]]; then
    echo "LOG: Скачивание Node Exporter Full (ID 1860)..."
    curl -sL https://grafana.com/api/dashboards/1860/revisions/37/download > config/grafana/dashboards/node-exporter.json
fi

if [[ "$DASHBOARD_CHOICE" == "2" || "$DASHBOARD_CHOICE" == "3" ]]; then
    echo "LOG: Скачивание cAdvisor Exporter (ID 14282)..."
    curl -sL https://grafana.com/api/dashboards/14282/revisions/1/download > config/grafana/dashboards/cadvisor.json
fi

# 6. Запуск инфраструктуры
echo "LOG: Запуск оркестрации Docker Compose..."
cd deploy
docker compose up -d

echo ""
echo "✅ Инфраструктура успешно развернута в режиме IaC!"
echo "Адрес: http://localhost:3000 | Логин: admin | Пароль: ${INPUT_GF_PASS}"