import os
import time
import random
from playwright.sync_api import sync_playwright

# Путь к файлу со списком URL (в той же директории, где лежит скрипт)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
URLS_FILE = os.path.join(BASE_DIR, "urls.txt")

def load_urls():
    if not os.path.exists(URLS_FILE):
        print(f"[!] Файл со списком URL не найден: {URLS_FILE}")
        return []
    
    with open(URLS_FILE, "r", encoding="utf-8") as f:
        # Читаем строки, убираем пробелы и пустые строки / комментарии
        urls = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    return urls

def warm_up_site(url):
    with sync_playwright() as p:
        # Запуск изолированного Chromium в headless-режиме
        browser = p.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
        )
        
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080}
        )
        
        page = context.new_page()
        
        try:
            print(f"[*] Прогрев сайта: {url}")
            page.goto(url, timeout=60000, wait_until="networkidle")
            
            # Рандомная пауза (имитация чтения контента)
            sleep_time = random.uniform(3, 6)
            time.sleep(sleep_time)
            
            # Имитация скроллинга вниз/вверх
            page.evaluate("window.scrollBy(0, 500);")
            time.sleep(random.uniform(1, 2.5))
            page.evaluate("window.scrollBy(0, -250);")
            
            # Попытка кликнуть по внутренней ссылке (если есть видимые)
            links = page.locator("a[href^='/'], a[href^='http']").all()
            visible_links = [l for l in links if l.is_visible()]
            
            if visible_links:
                target = random.choice(visible_links[:4])
                href = target.get_attribute("href")
                print(f"[-] Переход по ссылке: {href}")
                target.click()
                page.wait_for_load_state("networkidle")
                time.sleep(random.uniform(2, 4))
                
            print(f"[+] Успешно прогрето: {url}\n")
            
        except Exception as e:
            print(f"[!] Ошибка при прогреве {url}: {e}\n")
            
        finally:
            browser.close()

if __name__ == "__main__":
    urls = load_urls()
    if not urls:
        print("[!] Нет доступных URL для прогрева.")
    else:
        print(f"=== Старт прогрева: {len(urls)} сайтов ===")
        for site in urls:
            warm_up_site(site)
            time.sleep(random.uniform(3, 7))
        print("=== Прогрев завершен ===")
