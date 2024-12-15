import flask
import random
from google.cloud import storage
import os
import io

app = flask.Flask(__name__) 

BUCKET_NAME = 'csa-proj2324-mrbucket'
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'static/keys/asc_key.json'

# Initialize the Google Cloud Storage client
client = storage.Client()

# List of CDN server IPs in the region
cdn_servers = [
    '10.140.0.5',
    '10.128.0.6',
    '10.172.0.4'
]

# Simple function to select the best server (for now, random choice)
def select_best_server():
    return random.choice(cdn_servers)

@app.route('/get-image', methods=['GET'])
def get_image():
    image_path = flask.request.args.get('image_path')
    if not image_path:
        return flask.jsonify({'error': 'Image path is required'}), 400

    bucket = client.get_bucket(BUCKET_NAME)
    blob = bucket.blob(image_path)
    if not blob.exists():
        return flask.jsonify({'error': 'Image not found'}), 404

    img_bytes = blob.download_as_bytes()
    return flask.send_file(io.BytesIO(img_bytes), mimetype='image/jpeg')

@app.route('/get-video', methods=['GET'])
def get_video():
    video_path = flask.request.args.get('video_path')
    if not video_path:
        return flask.jsonify({'error': 'Video path is required'}), 400

    bucket = client.get_bucket(BUCKET_NAME)
    blob = bucket.blob(video_path)
    if not blob.exists():
        return flask.jsonify({'error': 'Video not found'}), 404

    video_bytes = blob.download_as_bytes()
    return flask.send_file(io.BytesIO(video_bytes), mimetype='video/mp4')

@app.route('/upload-image', methods=['POST'])
def upload_image():
    if 'file' not in flask.request.files:
        return flask.redirect(request.url)
    file = flask.request.files['file']
    if file.filename == '':
        return flask.redirect(request.url)
    if file:
        bucket = client.get_bucket(BUCKET_NAME)
        blob = bucket.blob(file.filename)
        blob.upload_from_file(file)
        return flask.redirect(flask.url_for('index'))

@app.route('/delete-image', methods=['POST'])
def delete_image():
    image_path = flask.request.form.get('image_path')
    if not image_path:
        return flask.jsonify({'error': 'Image path is required'}), 400

    bucket = client.get_bucket(BUCKET_NAME)
    blob = bucket.blob(image_path)
    if blob.exists():
        blob.delete()
        return flask.redirect(flask.url_for('index'))
    else:
        return flask.jsonify({'error': 'Image not found'}), 404

@app.route('/upload-video', methods=['POST'])
def upload_video():
    if 'file' not in request.files:
        return redirect(request.url)
    file = request.files['file']
    if file.filename == '':
        return redirect(request.url)
    if file:
        bucket = client.get_bucket(BUCKET_NAME)
        blob = bucket.blob(file.filename)
        blob.upload_from_file(file)
        return redirect(url_for('index'))

@app.route('/delete-video', methods=['POST'])
def delete_video():
    video_path = request.form.get('video_path')
    if not video_path:
        return jsonify({'error': 'Video path is required'}), 400

    bucket = client.get_bucket(BUCKET_NAME)
    blob = bucket.blob(video_path)
    if blob.exists():
        blob.delete()
        return redirect(url_for('index'))
    else:
        return jsonify({'error': 'Video not found'}), 404

@app.route("/")
def index():
    return flask.render_template("index.html")

@app.route('/cdn/lb/ip', methods=['GET'])
def get_cdn_ip():
    best_server = select_best_server()
    return flask.jsonify({'cdn_ip': best_server})

"""
@app.route('/cdn/lb/ip')
def get_load_balancer_ip():
    try:
        # Get the hostname of the machine running the load balancer
        hostname = socket.gethostname()
        # Get the IP address associated with the hostname
        ip_address = socket.gethostbyname(hostname)
        return jsonify(ip=ip_address)
    except Exception as e:
        return jsonify(error=str(e)), 500
"""

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080, debug=True)

