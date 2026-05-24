import subprocess
from flask import Flask, jsonify

app = Flask(__name__)


def _nsenter_shutdown(args: list[str]):
    """Run a shutdown command on the host via nsenter."""
    subprocess.Popen(["nsenter", "-t", "1", "-m", "-u", "-i", "-n", "--"] + args)


@app.route("/restart", methods=["POST"])
def restart():
    _nsenter_shutdown(["/sbin/shutdown", "-r", "now"])
    return jsonify({"status": "restarting"})


@app.route("/shutdown", methods=["POST"])
def shutdown():
    _nsenter_shutdown(["/sbin/shutdown", "-h", "now"])
    return jsonify({"status": "shutting down"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
