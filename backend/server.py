"""
Parking Gate Backend Node
Mensimulasikan gate parkir mall/apartemen dengan kecepatan berbeda:
  - GATE-UTAMA    : 2.0 detik  (gate lama/pintu utama yang sering macet)
  - GATE-EKSPRES  : 0.1 detik  (gate baru dengan sensor cepat)
  - GATE-KHUSUS   : 0.1 detik  (gate khusus penghuni/layanan prioritas)
"""
import os
import time
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

GATE_NAME = os.environ.get("GATE_NAME", "UNKNOWN-GATE")
PROCESSING_DELAY = float(os.environ.get("PROCESSING_DELAY", "1.0"))
SERVER_PORT = int(os.environ.get("SERVER_PORT", "5000"))

active_connections = 0
total_processed = 0
kendaraan_masuk = []

JENIS_GATE = {
    "GATE-UTAMA":  "Gerbang Utama (Lama, proses manual 2.0s)",
    "GATE-EKSPRES": "Gerbang Ekspres (Sensor RFID 0.1s)",
    "GATE-KHUSUS":  "Gerbang Khusus Penghuni (Kartu akses 0.1s)",
}


@app.route("/parkir", methods=["POST"])
def parkir():
    global active_connections, total_processed, kendaraan_masuk

    active_connections += 1
    data = request.get_json(silent=True) or {}

    plat_no = data.get("plat_no", "N/A")
    request_id = data.get("request_id", "N/A")
    jenis_kendaraan = data.get("jenis", "mobil")

    print(
        f"[{GATE_NAME}] 🚗 Kendaraan #{request_id} | "
        f"Plat: {plat_no} | Jenis: {jenis_kendaraan} |"
        f" ▶ Memproses..."
    )

    time.sleep(PROCESSING_DELAY)

    kendaraan_masuk.append({
        "request_id": request_id,
        "plat_no": plat_no,
        "gate": GATE_NAME,
        "jenis": jenis_kendaraan,
    })
    total_processed += 1
    active_connections -= 1

    response = {
        "gate": GATE_NAME,
        "plat_no": plat_no,
        "request_id": request_id,
        "jenis_kendaraan": jenis_kendaraan,
        "tipe_gate": JENIS_GATE.get(GATE_NAME, "UNKNOWN"),
        "waktu_proses_detik": PROCESSING_DELAY,
        "status": "MASUK",
        "lot_parkir": f"Lantai-{(total_processed % 5) + 1}",
        "gate_stats": {
            "antrean_aktif": active_connections,
            "total_diproses": total_processed,
        },
    }

    print(
        f"[{GATE_NAME}] ✅ Kendaraan #{request_id} | "
        f"Plat: {plat_no} | BERHASIL MASUK | "
        f"Antrean: {active_connections} | Total: {total_processed}"
    )
    return jsonify(response), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "gate": GATE_NAME,
        "status": "operasional",
        "tipe": JENIS_GATE.get(GATE_NAME, "UNKNOWN"),
        "antrean_aktif": active_connections,
        "total_diproses": total_processed,
    }), 200


@app.route("/stats", methods=["GET"])
def stats():
    return jsonify({
        "gate": GATE_NAME,
        "delay_proses": PROCESSING_DELAY,
        "antrean_aktif": active_connections,
        "total_diproses": total_processed,
        "kendaraan_terakhir": kendaraan_masuk[-5:] if kendaraan_masuk else [],
    }), 200


if __name__ == "__main__":
    print(f"[{GATE_NAME}] Sistem gate parkir aktif di port {SERVER_PORT}")
    print(f"[{GATE_NAME}] Kecepatan proses: {PROCESSING_DELAY} detik/kendaraan")
    app.run(host="0.0.0.0", port=SERVER_PORT, debug=False)
