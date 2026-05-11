#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2039
# Author: Valeriy Kornienko vikornienko76@gmail.com
####################################################
# Данный скрипт автоматизирует создание директорий и 
# установку зависимостей для старта проекта supportmeasures.
####################################################

set -euo pipefail

###################################################
# Переменные для настройки конфигурации.
###################################################

PY_VERSION="${SETUP_PY_VERSION:-3.13}"
REQUIRED_DIRS=("data/raw" "data/processed" "notebooks")
DEFAULT_DEPS=("pandas" "jupiter" "ipykernel")
NOTEBOOK_NAME="analysis.ipynb"

##################################################
# Логирование
##################################################

log() {
    local level="$1"; shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "\e[32m[${timestamp}] ℹ️  INFO: ${msg}\e[0m" ;;
        WARN)  echo -e "\e[33m[${timestamp}] ⚠️  WARN: ${msg}\e[0m" ;;
        ERROR) echo -e "\e[31m[${timestamp}] ❌ ERROR: ${msg}\e[0m" ;;
        OK)    echo -e "\e[34m[${timestamp}] ✅ ${msg}\e[0m" ;;
        *)     echo "[${timestamp}] ${level}: ${msg}" ;;
    esac
}

###################################################
# Проверки
###################################################

check_prerequisites() {
    if ! command -v uv &>/dev/null; then
        log "ERROR" "uv не установлен. Установите его: curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi
    
    if [[ "$PWD" == "/" || "$PWD" == "$HOME" ]]; then
        log "ERROR" "Не запускайте скрипт в корневой директории или домашней папке."
        exit 1
    fi
    log "OK" "Пререквизиты проверены."
}

####################################################
# Функции
####################################################

setup_directories() {
    log "INFO" "Проверка структуры директорий..."
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "INFO" "Создана директория: ${dir}/"
        else
            log "INFO" "Директория уже существует: ${dir}/"
        fi
    done
}

check_and_init_uv() {
    log "INFO" "Проверка виртуального окружения и инициализации uv..."
    
    # Проверяем наличие ключевых маркеров: .venv, .python-version, pyproject.toml
    if [[ -d ".venv" && -f ".python-version" && -f "pyproject.toml" ]]; then
        log "OK" "Проект uv и виртуальное окружение уже настроены. Пропускаю."
        return 0
    fi

    log "INFO" "Инициализация проекта uv с Python ${PY_VERSION}..."
    uv python pin "${PY_VERSION}"
    uv init . --bare || {
        log "ERROR" "Не удалось выполнить uv init."
        exit 1
    }

    log "OK" "Проект и виртуальное окружение успешно инициализированы."
}

add_dependencies() {
    log "INFO" "Установка зависимостей проекта..."
    uv add jupyterlab pandas
}

create_gitignore() {
    log "INFO" "Создание .gitignore..."
    if [[ -f ".gitignore" ]]; then
        log "WARN" ".gitignore уже существует. Пропускаю."
        return 0
    fi

    cat > .gitignore << 'GITIGNORE_EOF'
# Python
__pycache__/
*.py[cod]
*.$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environments
.venv/
env/
venv/
ENV/

# UV Manager
uv.lock

# IDE (VS Code)
.vscode/
*.code-workspace
.history/

# Jupyter
.ipynb_checkpoints/

# OS
.DS_Store
Thumbs.db

# Logs & Data
*.log
*.sqlite
data/raw/*.csv
logs/*.log
GITIGNORE_EOF
    log "OK" ".gitignore создан."
}

create_notebook() {
    log "INFO" "Создание Jupyter Notebook с импортом pandas..."
    local nb_path="notebooks/${NOTEBOOK_NAME}"
    
    if [[ -f "$nb_path" ]]; then
        log "WARN" "Ноутбук уже существует: ${nb_path}"
        return 0
    fi

    # Валидный JSON формат .ipynb (nbformat 4)
    cat > "$nb_path" << 'NOTEBOOK_EOF'
    {
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "init-pandas-import",
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "\n",
    "print(f\"✅ Pandas {pd.__version__} успешно импортирован.\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
NOTEBOOK_EOF
    log "OK" "Ноутбук создан: ${nb_path}"
}

#####################################################
# Точка входа
#####################################################

main() {
    log "INFO" "🚀 Запуск инициализации проекта в: $(pwd)"
    check_prerequisites
    setup_directories
    check_and_init_uv
    add_dependencies
    create_gitignore
    create_notebook
    
    log "OK" "🎉 Настройка проекта завершена успешно!"
    echo ""
    log "INFO" "💡 Рекомендации по работе:"
    log "INFO" "   Активировать окружение: source .venv/bin/activate"
    log "INFO" "   Запуск без активации:    uv run jupyter notebook"
    log "INFO" "   Добавить пакет:          uv add <package>"
}

main "$@"
