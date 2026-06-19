# PowerShell Script to Sync and Update engine_goWA with Upstream Repository
# Save this file as 'update_upstream.ps1' in the scripts folder of engine_goWA

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
# Translates to: UPSTREAM SYNC UTILITY - ENGINE_GOWA
Write-Host "      UPSTREAM SYNC UTILITY - ENGINE_GOWA" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure upstream remote is configured
Write-Host "[INFO] Memeriksa remote 'upstream'..." -ForegroundColor Yellow
$remotes = git remote
$hasUpstream = $false
foreach ($r in $remotes) {
    if ($r -eq "upstream") {
        $hasUpstream = $true
        break
    }
}

if (-not $hasUpstream) {
    Write-Host "[INFO] Remote 'upstream' belum terpasang. Menambahkan repositori asli..." -ForegroundColor Yellow
    git remote add upstream https://github.com/aldinokemal/go-whatsapp-web-multidevice.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Gagal menambahkan remote 'upstream'!" -ForegroundColor Red
        Exit
    }
    Write-Host "[SUCCESS] Remote 'upstream' berhasil dikonfigurasi." -ForegroundColor Green
} else {
    Write-Host "[SUCCESS] Remote 'upstream' terdeteksi." -ForegroundColor Green
}

# 2. Fetch latest changes from upstream
Write-Host "[INFO] Mengambil pembaruan terbaru dari upstream (repositori asli)..." -ForegroundColor Yellow
git fetch upstream
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Gagal mengambil data dari upstream! Periksa koneksi internet Anda." -ForegroundColor Red
    Exit
}
Write-Host "[SUCCESS] Pembaruan upstream berhasil diambil." -ForegroundColor Green

# 3. Get current branch
$branch = git branch --show-current
if ([string]::IsNullOrEmpty($branch)) {
    $branch = "main-custom"
}

# 4. Show commit differences
Write-Host ""
Write-Host "[INFO] Membandingkan branch lokal '$branch' dengan 'upstream/main'..." -ForegroundColor Yellow
$diffCommits = git log $branch..upstream/main --oneline
if ([string]::IsNullOrEmpty($diffCommits)) {
    Write-Host "[SUCCESS] Repositori lokal Anda sudah selaras dengan pembaruan terbaru dari upstream!" -ForegroundColor Green
    Exit
}

Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Daftar pembaruan baru dari upstream yang belum digabungkan:" -ForegroundColor Cyan
Write-Host $diffCommits
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow

# 5. Ask for confirmation before merging
$choice = Read-Host "Apakah Anda ingin menggabungkan (merge) pembaruan ini ke branch '$branch'? (y/n)"
if ($choice.ToLower() -ne "y") {
    Write-Host "[INFO] Penggabungan dibatalkan oleh pengguna." -ForegroundColor Yellow
    Exit
}

# 6. Perform merge
Write-Host "[INFO] Memulai penggabungan (git merge upstream/main)..." -ForegroundColor Yellow
try {
    # Run git merge (we temporarily relax preference to continue if merge fails with conflict)
    $ErrorActionPreference = "Continue"
    git merge upstream/main
    $mergeExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($mergeExit -ne 0) {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host "⚠️ TERJADI KONFLIK PENGGABUNGAN (MERGE CONFLICT)!" -ForegroundColor Red
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host "Sistem mendeteksi adanya konflik pada berkas lokal Anda." -ForegroundColor Yellow
        Write-Host "Silakan ikuti langkah berikut untuk menyelesaikannya:" -ForegroundColor Cyan
        Write-Host "1. Buka berkas yang berkonflik di editor kode Anda."
        Write-Host "2. Cari penanda konflik (<<<<<<<, =======, >>>>>>>) lalu selaraskan kodenya."
        Write-Host "3. Setelah selesai, jalankan perintah:"
        Write-Host "   git add <nama-berkas>" -ForegroundColor Yellow
        Write-Host "   git commit -m 'resolve merge conflicts with upstream'" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Red
    } else {
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host "🎉 PENGGABUNGAN SUKSES!" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host "Repositori engine_goWA Anda kini telah menggunakan versi terbaru." -ForegroundColor Green
        Write-Host "Silakan jalankan script rilis 'release.ps1' untuk memperbarui ke GitHub." -ForegroundColor Cyan
        Write-Host "==========================================================" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Terjadi kesalahan saat menjalankan perintah git merge!" -ForegroundColor Red
    Exit
}
