#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[-] Запустите скрипт с правами root: sudo bash install.sh"
  exit 1
}

INSTALL_DIR="/opt/site-warmup"

echo "[+] Создание директории проекта в $INSTALL_DIR..."
mkdir -p $INSTALL_DIR

echo "[+] Копирование файлов..."
cp warmup.py urls.txt requirements.txt $INSTALL_DIR/

echo "[+] Установка системных зависимостей (Python 3, Playwright системные либы)..."
apt update && apt install -y python3-pip python3-venv libglib2.0-0 libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libdbus-1-3 libexpat1 libxcb1 libxkbcommon0 libasound2t64 libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2 libxdamage1 libxshmfence1

echo "[+] Создание виртуального окружения Python..."
python3 -m venv $INSTALL_DIR/venv
source $INSTALL_DIR/venv/bin/activate

echo "[+] Установка Python-пакетов..."
pip install --upgrade pip
pip install -r $INSTALL_DIR/requirements.txt

echo "[+] Установка системных браузеров Playwright (Chromium)..."
$INSTALL_DIR/venv/bin/python -m playwright install chromium
$INSTALL_DIR/venv/bin/python -m playwright install-deps chromium

# Настройка Cron
echo ""
echo "=== Настройка расписания Cron ==="
echo "Выберите частоту запуска прогрева сайтов:"
echo "1) Каждые 2 часа (активный прогрев)"
echo "2) Каждые 4 часа (стандартный вариант, по умолчанию)"
echo "3) Каждые 12 часов (два раза в сутки)"
echo "4) Каждые 24 часа (один раз в сутки, например, ночью)"
echo "5) Свое расписание (кастомное)"
read -p "Введите номер варианта [1-5] (по умолчанию 2): " cron_choice

case $cron_choice in
    1)
        CRON_SCHEDULE="0 */2 * * *"
        DESC="каждые 2 часа"
        ;;
    3)
        CRON_SCHEDULE="0 */12 * * *"
        DESC="каждые 12 часов"
        ;;
    4)
        CRON_SCHEDULE="0 3 * * *"
        DESC="каждый день в 3:00 ночи"
        ;;
    5)
        read -p "Введите свое выражение Cron (например, '30 */3 * * *'): " custom_cron
        CRON_SCHEDULE="$custom_cron"
        DESC="пользовательское расписание ($custom_cron)"
        ;;
    *)
        CRON_SCHEDULE="0 */4 * * *"
        DESC="каждые 4 часа"
        ;;
esac

CRON_JOB="$CRON_SCHEDULE $INSTALL_DIR/venv/bin/python $INSTALL_DIR/warmup.py >> /var/log/site-warmup.log 2>&1"

# Добавляем задачу в crontab, заменяя старую, если она была
(crontab -l 2>/dev/null | grep -Fv "$INSTALL_DIR/warmup.py"; echo "$CRON_JOB") | crontab -

echo "--------------------------------------------------------"
echo "[+] Установка успешно завершена!"
echo "[+] Проект установлен в: $INSTALL_DIR"
echo "[+] Расписание Cron настроено: $DESC"
echo "[+] Логи работы сохраняются в: /var/log/site-warmup.log"
echo "[+] Ручной тест можно запустить командой:"
echo "    sudo $INSTALL_DIR/venv/bin/python $INSTALL_DIR/warmup.py"
echo "--------------------------------------------------------"
