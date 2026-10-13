# PCFORGE — конфигуратор ПК

Учебный проект: веб-интерфейс, Python/Flask backend, Microsoft SQL Server, Docker и GitHub Actions.

## Важно перед началом

- Проект рассчитан на **Microsoft SQL Server**, а не SQLite.
- SQL-файл `database/PCFORGE.sql` удаляет и заново создаёт таблицы при повторном запуске. Не запускай его повторно, если в базе уже есть важные данные, без резервной копии.
- Никогда не загружай `.env` и пароли в GitHub.

## Быстрый запуск на Windows без Docker

Подробная инструкция находится в `ИНСТРУКЦИЯ_ПО_ШАГАМ.md`. Коротко:

1. Установи Python 3.12+, SQL Server и SQL Server Management Studio (SSMS), а также Microsoft ODBC Driver 18 for SQL Server.
2. В SSMS открой `database/PCFORGE.sql` и выполни его (F5), если база ещё не создана.
3. Скопируй `.env.example` в файл `.env` и проверь имя SQL Server в `SQL_SERVER`.
4. В терминале из папки проекта выполни:

   ```powershell
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   py -m pip install -r backend/requirements.txt
   py -m pytest -q
   py backend/app.py
   ```

5. Открой `http://localhost:5000`. Для проверки базы открой `http://localhost:5000/api/health`.

## Запуск через Docker

Docker-контейнер на Windows не сможет автоматически использовать Windows Authentication на SQL Server хоста. Для этого варианта настрой в SQL Server TCP/IP и SQL Authentication, задай фиксированный TCP-порт (например, 1433) и создай SQL-логин с доступом к базе `PCFORGE`.

В PowerShell из корня проекта:

```powershell
$env:SQL_PASSWORD = "пароль_твоего_SQL_логина"
$env:SQL_USERNAME = "sa"
$env:SQL_SERVER_DOCKER = "host.docker.internal,1433"
docker compose config
docker compose up --build
```

Если используешь другой SQL-логин, замени `sa` на него. Если сервер слушает другой порт, замени `1433`. Затем открой `http://localhost:5000`. Остановка: `Ctrl+C`, затем `docker compose down`.

## GitHub Actions и публикация Docker-образа

Workflow `.github/workflows/build.yml` запускает тесты на push и pull request в `main`. При push в `main` после успешных тестов он собирает образ и публикует его в GitHub Container Registry (GHCR).

1. Создай пустой репозиторий на GitHub.
2. В терминале из корня проекта выполни `git init`, `git add .`, `git commit -m "Initial PCFORGE project"`.
3. Подключи репозиторий: `git branch -M main`, `git remote add origin https://github.com/ТВОЙ_ЛОГИН/ИМЯ_РЕПОЗИТОРИЯ.git`, затем `git push -u origin main`.
4. На GitHub открой вкладку **Actions** и дождись окончания workflow.
5. После успешного запуска открой раздел **Packages** профиля/репозитория и проверь опубликованный образ.

Для публикации workflow использует встроенный `GITHUB_TOKEN`; вручную создавать токен и записывать пароль в файлы не нужно. В настройках репозитория в **Settings → Actions → General → Workflow permissions** разреши запись, если GitHub просит это сделать.

## API

- `/api/health` — подключение к SQL Server
- `/api/categories` — список категорий
- `/api/components` — комплектующие
- `/api/builds` — сборки
- `/api/compatibility` — упрощённая проверка комплектующих
- `/api/orders` — заказы

## Ограничения учебной версии

Проверка совместимости упрощённая; авторизация и оплата не являются полноценными production-сервисами. Не используй реальные пароли пользователей или платёжные данные.
