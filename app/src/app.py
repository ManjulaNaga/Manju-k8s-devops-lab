"""Demo service deployed by the pipeline."""
import os

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)

    def version() -> str:
        return os.environ.get("APP_VERSION", "dev")

    def environment() -> str:
        return os.environ.get("APP_ENV", "local")

    @app.get("/")
    def index():
        return jsonify(
            message="Hello Manju, from Kubernetes, Terraform, Jenkins! ",
            environment=environment(),
            version=version(),
            pod=os.environ.get("HOSTNAME", "unknown"),
        )

    @app.get("/healthz")
    def healthz():
        return jsonify(status="ok")

    @app.get("/readyz")
    def readyz():
        return jsonify(status="ready")

    @app.get("/version")
    def version_route():
        return jsonify(version=version())

    return app


app = create_app()
