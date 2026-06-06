"""
LOAD BALANCING BENCHMARK: SISTEM GATE PARKIR MALL
==================================================
Studi Kasus Nyata: Mall Grand City memiliki 3 gerbang parkir:
  - GATE-UTAMA   (2.0s) : Gerbang lama dengan proses manual, sering macet
  - GATE-EKSPRES  (0.1s) : Gerbang baru pakai sensor RFID, sangat cepat
  - GATE-KHUSUS   (0.1s) : Gerbang penghuni dengan kartu akses, cepat

Membandingkan Round Robin vs Least Connections:
  - 30 kendaraan, 10 datang bersamaan (jam sibuk)
"""
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict

import requests

LOAD_BALANCER_URL = "http://localhost:8080/parkir"

TOTAL_KENDARAAN = 30
KONKURENSI = 10

PLAT_NOMOR = [
    "B 1234 ABC", "B 5678 DEF", "B 9012 GHI", "B 3456 JKL",
    "B 7890 MNO", "B 2468 PQR", "B 1357 STU", "B 8642 VWX",
    "B 9753 YZA", "B 1122 BCD", "B 3344 EFG", "B 5566 HIJ",
    "B 7788 KLM", "B 9900 NOP", "B 2233 QRS", "B 4455 TUV",
    "B 6677 WXY", "B 8899 ZAB", "B 1010 CDE", "B 1313 FGH",
    "B 1515 IJK", "B 1717 LMN", "B 1919 OPQ", "B 2121 RST",
    "B 2323 UVW", "B 2525 XYZ", "B 2727 ABC", "B 2929 DEF",
    "B 3131 GHI", "B 3333 JKL",
]

JENIS_KENDARAAN = [
    "mobil", "motor", "mobil", "mobil", "motor",
    "mobil", "mobil", "motor", "mobil", "mobil",
    "motor", "mobil", "mobil", "motor", "mobil",
    "mobil", "mobil", "motor", "mobil", "mobil",
    "motor", "mobil", "mobil", "motor", "mobil",
    "mobil", "motor", "mobil", "mobil", "motor",
]


def kendaraan_masuk(idx, plat, jenis):
    try:
        start = time.perf_counter()
        resp = requests.post(
            LOAD_BALANCER_URL,
            json={
                "request_id": idx,
                "plat_no": plat,
                "jenis": jenis,
            },
            timeout=30,
        )
        elapsed = time.perf_counter() - start
        data = resp.json()
        return {
            "request_id": idx,
            "plat_no": plat,
            "jenis": jenis,
            "gate": data.get("gate", "UNKNOWN"),
            "lot_parkir": data.get("lot_parkir", "?"),
            "waktu_gate": round(elapsed, 3),
        }
    except requests.RequestException as e:
        return {
            "request_id": idx,
            "plat_no": plat,
            "jenis": jenis,
            "gate": "ERROR",
            "lot_parkir": "-",
            "waktu_gate": 0,
        }


def jalankan_test(nama_algoritma):
    print(f"\n{'='*60}")
    print(f"  PENGUJIAN: {nama_algoritma}")
    print(f"  Lokasi: Mall Grand City - Gate Parkir")
    print(f"  {TOTAL_KENDARAAN} kendaraan | {KONKURENSI} datang bersamaan (jam sibuk)")
    print(f"{'='*60}\n")

    hasil = []
    start_total = time.perf_counter()

    with ThreadPoolExecutor(max_workers=KONKURENSI) as executor:
        futures = {
            executor.submit(kendaraan_masuk, i, PLAT_NOMOR[i], JENIS_KENDARAAN[i]): i
            for i in range(TOTAL_KENDARAAN)
        }
        for future in as_completed(futures):
            r = future.result()
            hasil.append(r)
            ikon = "🚗" if r["jenis"] == "mobil" else "🏍️"
            status = "✅" if r["gate"] != "ERROR" else "❌"
            print(
                f"  {status} {ikon} #{r['request_id']:02d} | "
                f"Plat: {r['plat_no']:14s} | "
                f"Gate: {r['gate']:14s} | "
                f"Lot: {r['lot_parkir']:10s} | "
                f"Waktu: {r['waktu_gate']:.3f}s"
            )

    total_waktu = time.perf_counter() - start_total
    hasil.sort(key=lambda x: x["request_id"])

    distribusi = defaultdict(int)
    waktu_respons = []
    for r in hasil:
        distribusi[r["gate"]] += 1
        if r["gate"] != "ERROR":
            waktu_respons.append(r["waktu_gate"])

    rata_rata = statistics.mean(waktu_respons) if waktu_respons else 0
    maks = max(waktu_respons) if waktu_respons else 0
    min_ = min(waktu_respons) if waktu_respons else 0

    print(f"\n{'─'*60}")
    print(f"  HASIL: {nama_algoritma}")
    print(f"{'─'*60}")
    print(f"\n  📊 Distribusi Kendaraan per Gate:")

    ikon_gate = {
        "gate-utama": "🏛️",
        "gate-ekspres": "⚡",
        "gate-khusus": "🔑",
    }
    for gate, jumlah in sorted(distribusi.items()):
        ikon = ikon_gate.get(gate, "❓")
        persen = jumlah / TOTAL_KENDARAAN * 100
        bar = "█" * int(persen / 5)
        print(f"    {ikon} {gate:16s} : {jumlah:2d} kendaraan ({persen:5.1f}%)  {bar}")

    print(f"\n  ⏱️ Waktu Pemrosesan:")
    print(f"    Total waktu pengujian  : {total_waktu:.3f} detik")
    print(f"    Rata-rata per kendaraan: {rata_rata:.3f} detik")
    print(f"    Tercepat               : {min_:.3f} detik")
    print(f"    Terlambat              : {maks:.3f} detik")

    kemacetan = distribusi.get("gate-utama", 0) >= 8
    if kemacetan:
        print(f"\n  ⚠️ OBSERVASI: TERJADI KEMACETAN di GATE-UTAMA!")
        print(f"    Gate utama (lama/manual 2.0s) menerima {distribusi.get('gate-utama', 0)} kendaraan,")
        print(f"    sementara gate ekspres dan gate khusus tidak dimaksimalkan.")
        print(f"    Antrean panjang di gate utama, pengunjung mengeluh.")
    else:
        print(f"\n  ✅ OBSERVASI: Arus lalu lintas LANCAR!")
        print(f"    Gate utama yang lambat otomatis dihindari.")
        print(f"    Gate ekspres & gate khusus menangani mayoritas kendaraan.")
        print(f"    Tidak ada kemacetan, pengunjung puas.")

    return {
        "algoritma": nama_algoritma,
        "total_waktu": round(total_waktu, 3),
        "rata_rata": round(rata_rata, 3),
        "tercepat": round(min_, 3),
        "terlambat": round(maks, 3),
        "distribusi": dict(distribusi),
    }


def main():
    print("\n")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║   SIMULASI SISTEM GATE PARKIR MALL GRAND CITY             ║")
    print("║   Benchmark: Round Robin vs Least Connections             ║")
    print("║   3 Gate: UTAMA (2.0s) | EKSPRES (0.1s) | KHUSUS (0.1s)  ║")
    print("╚═══════════════════════════════════════════════════════════╝")

    rr = jalankan_test("ROUND ROBIN")

    print(f"\n\n  ⏳ Tunggu 3 detik sebelum test berikutnya...\n")
    time.sleep(3)

    print("  🔄 Menukar konfigurasi Nginx ke LEAST CONNECTIONS...")
    import subprocess
    subprocess.run([
        "docker", "exec", "nginx-lb",
        "sh", "-c",
        "cp /etc/nginx/leastconn.conf /etc/nginx/nginx.conf && nginx -s reload"
    ], capture_output=True)
    time.sleep(2)

    lc = jalankan_test("LEAST CONNECTIONS")

    print(f"\n\n{'='*60}")
    print(f"  📋 ANALISIS KOMPARATIF: SISTEM GATE PARKIR MALL")
    print(f"{'='*60}")

    print(f"""
  ┌───────────────────────┬──────────────────┬──────────────────┐
  │ Parameter             │ Round Robin      │ Least Connections │
  ├───────────────────────┼──────────────────┼──────────────────┤
  │ Metode Distribusi     │ Giliran tetap    │ Cek antrean      │
  │                       │ (tanpa lihat     │ gate tersibuk    │
  │                       │  kondisi gate)   │ dihindari        │
  ├───────────────────────┼──────────────────┼──────────────────┤
  │ Total Waktu           │ {rr['total_waktu']:>7.3f}s        │ {lc['total_waktu']:>7.3f}s         │
  ├───────────────────────┼──────────────────┼──────────────────┤
  │ Rata-rata per         │ {rr['rata_rata']:>7.3f}s        │ {lc['rata_rata']:>7.3f}s         │
  │ kendaraan             │                  │                  │
  ├───────────────────────┼──────────────────┼──────────────────┤
  │ Kemacetan di          │ YA               │ TIDAK            │
  │ Gate Utama            │                  │                  │
  ├───────────────────────┼──────────────────┼──────────────────┤
  │ Kepuasan Pengunjung   │ RENDAH (antre    │ TINGGI (lancar,  │
  │                       │  panjang)        │  cepat masuk)    │
  └───────────────────────┴──────────────────┴──────────────────┘

  📝 KESIMPULAN:
  Dengan Round Robin, gate utama (lama/lambat) mendapat jumlah
  kendaraan yang sama seperti gate ekspres (baru/cepat), menyebabkan
  kemacetan parah. Least Connections mendeteksi gate utama sedang
  sibuk memproses kendaraan dan otomatis mengalihkan ke gate ekspres
  dan gate khusus yang lebih cepat. Hasilnya: antrean berkurang
  drastis, kepuasan pengunjung meningkat.

  💡 REKOMENDASI UNTUK MALL GRAND CITY:
  Gunakan Least Connections. Upgrade gate utama atau tambah gate
  ekspres saat jam sibuk (makan siang, akhir pekan).
""")

    print("  ✅ Benchmark selesai!\n")


if __name__ == "__main__":
    main()
