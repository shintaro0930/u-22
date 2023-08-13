from flask import Flask, jsonify, request
from flask_cors import CORS
import paypayopa


API_KEY="a_skHc4tc3WQ_PD4m"
API_SECRET="ex7PTkYWG/b68MronstUx6Va7JJnXvdCZG8WoE4Owug="

client = paypayopa.Client(auth=(API_KEY, API_SECRET),
                        production_mode=False)
client.set_assume_merchant("563062778299113472")
app = Flask(__name__)
CORS(app)


@app.route('/v2/codes', methods=["POST"])
def test():
    output = {}
    data = request.get_json()
    response = client.Code.create_qr_code(data)
    output["redirectUrl"] = response['data']['url']
    print(output)
    return jsonify(output)

if __name__ == "__main__":
    app.run(port=5001, debug=True)