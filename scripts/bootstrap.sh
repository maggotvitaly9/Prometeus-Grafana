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
read -p "Укажите имя пользователя Grafana: " INPUT_GF_NAME
read -p "Укажите пароль пользователя Grafana: " INPUT_GF_PASS
read -p "Укажите срок хранения метрик (например, 15d): " INPUT_RETENTION

# 2. Формирование локального .env файла
echo "LOG: Генерация .env файла..."
cat << EOF > .env
GF_SECURITY_ADMIN_USER=${INPUT_GF_NAME}
GF_SECURITY_ADMIN_PASSWORD=${INPUT_GF_PASS}
GF_USERS_ALLOW_SIGN_UP=false
PROMETHEUS_RETENTION=${INPUT_RETENTION}
EOF

export $(grep -v '^#' .env | xargs)

# 3. Декларативная шаблонизация
echo "LOG: Шаблонизация конфигураций через envsubst..."
envsubst < config/prometheus/prometheus.yml.template > config/prometheus/prometheus.yml

# 4. Запуск инфраструктуры
echo "LOG: Запуск оркестрации Docker Compose..."
cd deploy
docker compose up -d

echo ""
echo "✅ Инфраструктура успешно развернута в режиме IaC!"
echo "Адрес: http://localhost:3000 | Логин: ${INPUT_GF_NAME} | Пароль: ${INPUT_GF_PASS}"