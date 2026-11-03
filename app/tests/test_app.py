import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from app import create_app  # noqa: E402


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "abc123")
    monkeypatch.setenv("APP_ENV", "test")
    return create_app().test_client()


def test_index_reports_environment_and_version(client):
    body = client.get("/").get_json()
    assert body["environment"] == "test"
    assert body["version"] == "abc123"


@pytest.mark.parametrize("path", ["/healthz", "/readyz"])
def test_probes_return_200(client, path):
    assert client.get(path).status_code == 200


def test_version_endpoint(client):
    assert client.get("/version").get_json() == {"version": "abc123"}


def test_unknown_route_returns_404(client):
    assert client.get("/nope").status_code == 404
