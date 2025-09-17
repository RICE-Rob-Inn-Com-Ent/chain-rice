from flask import Flask, jsonify, request

app = Flask(__name__)


@app.get("/hello")
def hello():
    name = request.args.get("name", "World")
    return jsonify({"message": f"Hello, {name}!"})


def run() -> None:
    app.run(host="0.0.0.0", port=8000, debug=True)


if __name__ == "__main__":
    run()


