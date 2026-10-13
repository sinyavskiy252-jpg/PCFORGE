import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))
import app

def test_categories():
    client = app.app.test_client()
    r = client.get("/api/categories")
    assert r.status_code == 200
    assert "Процессор" in r.json

def test_health_route_exists():
    client = app.app.test_client()
    r = client.get("/api/health")
    assert r.status_code in (200, 503)
