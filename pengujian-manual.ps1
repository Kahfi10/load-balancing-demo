Clear-Host
Write-Host "+---------------------------------------------+" -ForegroundColor Cyan
Write-Host "|  PENGUJIAN MANUAL: LOAD BALANCING GATE PARKIR |" -ForegroundColor Cyan
Write-Host "|  Round Robin vs Least Connections             |" -ForegroundColor Cyan
Write-Host "|  Mall Grand City - 3 Gate Parkir              |" -ForegroundColor Cyan
Write-Host "+---------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PRASYARAT
# ============================================================
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " PRASYARAT" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Pada pengujian ini kita akan membandingkan algoritma Round Robin"
Write-Host " dan Least Connections menggunakan sistem Gate Parkir Mall Grand City"
Write-Host " yang memiliki 3 gerbang dengan kecepatan berbeda.'"
Write-Host ""
Write-Host "Pastikan:" -ForegroundColor Yellow
Write-Host "  1. Docker Desktop sudah running"
Write-Host "  2. Tidak ada container lama yang masih berjalan"
Write-Host ""
Write-Host "Tekan ENTER untuk mulai..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 1: BUILD & START CONTAINER
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 1: BUILD & START CONTAINER (Round Robin)" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Pertama kita jalankan semua container dengan konfigurasi Round Robin."
Write-Host " Perhatikan di docker-compose.yml, Nginx menggunakan Round Robin"
Write-Host " sebagai algoritma default load balancing-nya.'"
Write-Host ""
Write-Host "Jalankan perintah:" -ForegroundColor Cyan
Write-Host "  docker-compose down -v" -ForegroundColor White
Write-Host "  docker-compose up -d --build" -ForegroundColor White
Write-Host ""
Write-Host "Setelah selesai, lanjutkan..." -ForegroundColor Gray
Write-Host "Tekan ENTER untuk lanjut..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 2: VERIFIKASI GATE
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 2: VERIFIKASI SEMUA GATE AKTIF" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Kita verifikasi ketiga gate sudah berjalan dengan benar.'"
Write-Host ""
Write-Host "Jalankan perintah:" -ForegroundColor Cyan
Write-Host "  curl http://localhost:5001/health" -ForegroundColor White
Write-Host "  curl http://localhost:5002/health" -ForegroundColor White
Write-Host "  curl http://localhost:5003/health" -ForegroundColor White
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Gate Utama berjalan di port 5001 dengan delay 2.0 detik (manual)."
Write-Host " Gate Ekspres di port 5002 dengan delay 0.1 detik (RFID)."
Write-Host " Gate Khusus di port 5003 dengan delay 0.1 detik (kartu akses).'"
Write-Host ""
Write-Host "[SCREENSHOT]: Output health check dari 3 gate" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tekan ENTER untuk lanjut..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 3: JALANKAN DOCKER STATS (terminal terpisah)
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 3: BUKA DOCKER STATS (TERMINAL KEDUA)" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Kita buka terminal kedua untuk memantau resource container"
Write-Host " secara real-time menggunakan docker stats.'"
Write-Host ""
Write-Host "BUKA TERMINAL BARU (PowerShell) lalu jalankan:" -ForegroundColor Cyan
Write-Host "  docker stats" -ForegroundColor White
Write-Host ""
Write-Host "Biarkan docker stats berjalan di terminal tersebut."
Write-Host "Kita akan kembali ke terminal ini untuk menjalankan benchmark." -ForegroundColor Gray
Write-Host ""
Write-Host "[SCREENSHOT]: Tampilan docker stats (keempat container)" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tekan ENTER untuk lanjut ke pengujian Round Robin..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 4: TEST ROUND ROBIN
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 4: PENGUJIAN ROUND ROBIN" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Sekarang kita kirim 30 kendaraan dengan 10 kendaraan datang"
Write-Host " bersamaan (simulasi jam sibuk). Round Robin akan mendistribusikan"
Write-Host " secara bergiliran tanpa melihat kondisi gate.'"
Write-Host ""
Write-Host "Jalankan perintah:" -ForegroundColor Cyan
Write-Host "  python benchmark.py" -ForegroundColor White
Write-Host ""
Write-Host "[PERHATIAN]:" -ForegroundColor Red
Write-Host "  Script akan menjalankan Round Robin dulu, lalu otomatis"
Write-Host "  beralih ke Least Connections. CEPAT - CEOK terminal docker stats"
Write-Host "  untuk screenshot saat Round Robin sedang berjalan !"
Write-Host ""
Write-Host "[SCREENSHOT 1 (GAMBAR 2)]: Output Round Robin" -ForegroundColor Magenta
Write-Host "     - Tangkap hasil distribusi: ~10 kendaraan per gate" -ForegroundColor Magenta
Write-Host "[SCREENSHOT 2 (GAMBAR 3)]: docker stats saat RR jalan" -ForegroundColor Magenta
Write-Host "     - Tangkap beban: gate-utama tinggi, gate lain rendah" -ForegroundColor Magenta
Write-Host ""
Write-Host "Katakan setelah melihat hasil:" -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "'Terlihat gate utama menerima 10 kendaraan - sama banyaknya dengan"
Write-Host " gate ekspres dan gate khusus. Akibatnya gate utama yang lambat"
Write-Host " (2.0 detik) menjadi bottleneck. Total waktu ~20 detik."
Write-Host " Terjadi kemacetan!'"
Write-Host ""
Write-Host "Tekan ENTER untuk melanjutkan ke Least Connections..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 5: SWITCH KE LEAST CONNECTIONS (manual fallback)
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 5: BERPINDAH KE LEAST CONNECTIONS" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Sekarang kita ganti algoritma ke Least Connections."
Write-Host " Nginx akan memeriksa jumlah antrean di setiap gate sebelum"
Write-Host " mengirimkan kendaraan baru.'"
Write-Host ""
Write-Host "Cara 1 - Otomatis (oleh benchmark.py):" -ForegroundColor Cyan
Write-Host "  Jika benchmark.py masih berjalan, script akan otomatis" -ForegroundColor White
Write-Host "  mengganti konfigurasi via docker exec." -ForegroundColor White
Write-Host ""
Write-Host "Cara 2 - Manual (jika perlu restart):" -ForegroundColor Cyan
Write-Host "  docker compose down" -ForegroundColor White
Write-Host "  (edit docker-compose.yml: ganti roundrobin.conf jadi leastconn.conf)" -ForegroundColor White
Write-Host "  docker compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "[SCREENSHOT (opsional)]: Perintah switch konfigurasi" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tekan ENTER untuk lanjut..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 6: TEST LEAST CONNECTIONS
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 6: PENGUJIAN LEAST CONNECTIONS" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Setelah algoritma diganti, kita jalankan pengujian yang sama:"
Write-Host " 30 kendaraan, 10 datang bersamaan.'"
Write-Host ""
Write-Host "Jika benchmark.py sudah otomatis menjalankan ini, amati outputnya." -ForegroundColor Gray
Write-Host "Jika tidak, jalankan manual:" -ForegroundColor Gray
Write-Host "  python benchmark.py" -ForegroundColor White
Write-Host ""
Write-Host "[SCREENSHOT 1 (GAMBAR 4)]: Output Least Connections" -ForegroundColor Magenta
Write-Host "     - Tangkap hasil: gate utama ~3-5, gate lain ~12-14" -ForegroundColor Magenta
Write-Host "[SCREENSHOT 2 (GAMBAR 5)]: docker stats saat LC jalan" -ForegroundColor Magenta
Write-Host "     - Tangkap beban: gate-utama rendah, gate lain tinggi" -ForegroundColor Magenta
Write-Host ""
Write-Host "Katakan setelah melihat hasil:" -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "'Sekarang gate utama hanya menangani 3-5 kendaraan karena Nginx"
Write-Host " mendeteksi gate ini sibuk. Gate ekspres dan gate khusus menangani"
Write-Host " sisanya. Total waktu turun dari ~20 detik menjadi ~3 detik -"
Write-Host " peningkatan 6.5x lipat. Tidak ada kemacetan!'"
Write-Host ""
Write-Host "Tekan ENTER untuk lihat analisis komparatif..." -ForegroundColor Gray
$null = Read-Host

# ============================================================
# LANGKAH 7: ANALISIS KOMPARATIF
# ============================================================
Clear-Host
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 7: ANALISIS KOMPARATIF" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Katakan: " -NoNewline -ForegroundColor Green
Write-Host "'Mari kita bandingkan kedua algoritma:'"
Write-Host ""
Write-Host "  +-----------------------+------------------+------------------+" -ForegroundColor Cyan
Write-Host "  | Parameter             | Round Robin      | Least Connections |" -ForegroundColor Cyan
Write-Host "  +-----------------------+------------------+------------------+" -ForegroundColor Cyan
Write-Host "  | Distribusi           | 10-10-10 (sama)  | 3-13-14 (adaptif) |" -ForegroundColor Cyan
Write-Host "  | Total Waktu          | ~20 detik        | ~3 detik          |" -ForegroundColor Cyan
Write-Host "  | Rata-rata/kendaraan  | ~2.1 detik       | ~0.3 detik        |" -ForegroundColor Cyan
Write-Host "  | Kemacetan            | YA               | TIDAK             |" -ForegroundColor Cyan
Write-Host "  | Kepuasan Pengunjung  | RENDAH           | TINGGI            |" -ForegroundColor Cyan
Write-Host "  +-----------------------+------------------+------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Host "[SCREENSHOT (GAMBAR 6)]: Output analisis komparatif" -ForegroundColor Magenta
Write-Host "     dari benchmark.py atau tabel di atas" -ForegroundColor Magenta
Write-Host ""
Write-Host "Katakan:" -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "'Kesimpulannya: Least Connections 6.5x lebih cepat dari Round Robin"
Write-Host " untuk skenario gate parkir dengan variasi kecepatan ini."
Write-Host " Rekomendasi untuk Mall Grand City: gunakan Least Connections"
Write-Host " dan upgrade gate utama yang lambat.'"
Write-Host ""

# ============================================================
# LANGKAH 8: CLEANUP
# ============================================================
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host " LANGKAH 8: CLEANUP (Opsional)" -ForegroundColor Yellow
Write-Host ('='*63) -ForegroundColor Yellow
Write-Host ""
Write-Host "Jalankan jika selesai:" -ForegroundColor Cyan
Write-Host "  docker compose down" -ForegroundColor White
Write-Host ""
Write-Host "Pengujian selesai! [OK]" -ForegroundColor Green
Write-Host ""
Write-Host ('='*63) -ForegroundColor Cyan
Write-Host " RINGKASAN SCREENSHOT YANG DIAMBIL:" -ForegroundColor Cyan
Write-Host ('='*63) -ForegroundColor Cyan
Write-Host ""
Write-Host "  [GAMBAR 2]: Output Round Robin (distribusi 10-10-10)" -ForegroundColor Magenta
Write-Host "  [GAMBAR 3]: docker stats saat Round Robin" -ForegroundColor Magenta
Write-Host "  [GAMBAR 4]: Output Least Connections (distribusi 3-13-14)" -ForegroundColor Magenta
Write-Host "  [GAMBAR 5]: docker stats saat Least Connections" -ForegroundColor Magenta
Write-Host "  [GAMBAR 6]: Tabel analisis komparatif" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tekan ENTER untuk keluar..." -ForegroundColor Gray
$null = Read-Host
