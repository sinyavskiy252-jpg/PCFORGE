import os
from pathlib import Path
from flask import Flask, jsonify, request, send_from_directory
import pyodbc
from dotenv import load_dotenv

BASE = Path(__file__).resolve().parent.parent
FRONTEND = BASE / "frontend"
load_dotenv(BASE / ".env")

app = Flask(__name__, static_folder=str(FRONTEND), static_url_path="")

CATEGORIES = [
    "Процессор", "Видеокарта", "Материнская плата", "Оперативная память",
    "SSD", "Блок питания", "Охлаждение", "Корпус"
]

def connection_string():
    # Заменяем localhost на host.docker.internal, чтобы контейнер видел базу на Windows
    server = os.getenv("SQL_SERVER", r"host.docker.internal,1433")
    database = os.getenv("SQL_DATABASE", "PCFORGE")
    driver = os.getenv("SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    
    # Берем логин и пароль, переданные через терминал (по умолчанию docker_user)
    user = os.getenv("SQL_USERNAME", "docker_user")
    password = os.getenv("SQL_PASSWORD", "")
    
    # Принудительно отключаем Trusted_Connection и разрешаем недоверенные сертификаты
    return f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};UID={user};PWD={password};Trusted_Connection=no;TrustServerCertificate=yes;"

def get_connection():
    return pyodbc.connect(connection_string(), timeout=5)

def rows_as_dict(cursor):
    columns = [c[0] for c in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]

@app.route("/")
def index():
    return send_from_directory(FRONTEND, "index.html")

@app.route("/api/health")
def health():
    try:
        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute("SELECT DB_NAME() AS database_name")
            db_name = cur.fetchone()[0]
        return jsonify({"status":"ok", "project":"PCFORGE", "database":"SQL Server", "database_name":db_name})
    except Exception as exc:
        return jsonify({"status":"error", "project":"PCFORGE", "database":"SQL Server", "error":str(exc)}), 503

@app.route("/api/categories")
def categories():
    return jsonify(CATEGORIES)

@app.route("/api/components")
def components():
    category = request.args.get("category")
    q = request.args.get("q", "").strip()
    try:
        with get_connection() as conn:
            cur = conn.cursor()
            sql = """
                SELECT C.ComponentID AS id, CAT.CategoryName AS category,
                       C.ComponentName AS name, C.Description AS description,
                       CAST(C.Price AS float) AS price
                FROM Components C
                INNER JOIN Categories CAT ON CAT.CategoryID = C.CategoryID
                WHERE 1=1
            """
            params=[]
            if category and category != "Все категории":
                sql += " AND CAT.CategoryName = ?"
                params.append(category)
            if q:
                sql += " AND (C.ComponentName LIKE ? OR C.Description LIKE ?)"
                params += [f"%{q}%", f"%{q}%"]
            sql += " ORDER BY CAT.CategoryID, C.Price"
            cur.execute(sql, params)
            return jsonify(rows_as_dict(cur))
    except Exception as exc:
        return jsonify({"error":str(exc)}), 500

@app.route("/api/builds", methods=["GET", "POST"])
def builds():
    try:
        with get_connection() as conn:
            cur=conn.cursor()
            if request.method == "GET":
                cur.execute("SELECT BuildID AS id, BuildName AS name, CAST(TotalPrice AS float) AS total_price, CreatedAt AS created_at FROM Builds ORDER BY BuildID DESC")
                return jsonify(rows_as_dict(cur))
            data=request.get_json(force=True)
            name=data.get("name", "Моя сборка")
            ids=[int(x) for x in data.get("component_ids", [])]
            if not ids: return jsonify({"error":"Нет выбранных комплектующих"}),400
            marks=",".join("?" for _ in ids)
            cur.execute(f"SELECT ComponentID, Price FROM Components WHERE ComponentID IN ({marks})", ids)
            components=cur.fetchall()
            if not components: return jsonify({"error":"Комплектующие не найдены"}),400
            total=sum(float(r.Price) for r in components)
            cur.execute("INSERT INTO Builds(UserID,BuildName,TotalPrice) OUTPUT INSERTED.BuildID VALUES(?,?,?)", (1,name,total))
            build_id=cur.fetchone()[0]
            for cid in ids:
                cur.execute("INSERT INTO BuildComponents(BuildID,ComponentID) VALUES(?,?)", (build_id,cid))
            conn.commit()
            return jsonify({"id":build_id,"name":name,"total_price":total}),201
    except Exception as exc:
        return jsonify({"error":str(exc)}),500

@app.route("/api/compatibility", methods=["POST"])
def compatibility():
    data=request.get_json(force=True)
    ids=[int(x) for x in data.get("component_ids", [])]
    try:
        with get_connection() as conn:
            cur=conn.cursor()
            if ids:
                marks=",".join("?" for _ in ids)
                cur.execute(f"SELECT C.ComponentID, CAT.CategoryName FROM Components C INNER JOIN Categories CAT ON CAT.CategoryID=C.CategoryID WHERE C.ComponentID IN ({marks})", ids)
                cats={r.CategoryName for r in cur.fetchall()}
            else: cats=set()
            checks=[
                ("Процессор ↔ Материнская плата", {"Процессор","Материнская плата"} <= cats),
                ("ОЗУ ↔ Материнская плата", {"Оперативная память","Материнская плата"} <= cats),
                ("Видеокарта ↔ Корпус", {"Видеокарта","Корпус"} <= cats),
                ("Блок питания", "Блок питания" in cats),
            ]
            return jsonify({"compatible":all(v for _,v in checks),"checks":[{"name":n,"status":"ok" if v else "warning"} for n,v in checks]})
    except Exception as exc:
        return jsonify({"error":str(exc)}),500

@app.route("/api/orders", methods=["GET","POST"])
def orders():
    try:
        with get_connection() as conn:
            cur=conn.cursor()
            if request.method=="GET":
                cur.execute("SELECT OrderID AS id, CAST(TotalPrice AS float) AS total_price, Status AS status, CreatedAt AS created_at FROM Orders ORDER BY OrderID DESC")
                return jsonify(rows_as_dict(cur))
            data=request.get_json(force=True)
            build_id=data.get("build_id")
            total=float(data.get("total_price",0))
            cur.execute("INSERT INTO Orders(UserID,BuildID,TotalPrice,Status) OUTPUT INSERTED.OrderID VALUES(?,?,?,?)", (1,build_id,total,"Оплачен"))
            order_id=cur.fetchone()[0]
            conn.commit()
            return jsonify({"id":order_id,"status":"Оплачен","total_price":total}),201
    except Exception as exc:
        return jsonify({"error":str(exc)}),500

if __name__ == "__main__":
    # Включаем параметр debug=True для подробных логов в консоли Docker
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=True)
