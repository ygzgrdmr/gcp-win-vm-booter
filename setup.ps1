# Loglama için fonksiyonlar
function Log {
    param ([string]$message)
    Write-Host "[INFO] $message" -ForegroundColor Green
}

function LogError {
    param ([string]$message)
    Write-Host "[ERROR] $message" -ForegroundColor Red
    exit 1
}

# Temp Dizinini Oluştur
if (-not (Test-Path "C:\temp")) {
    Log "C:\temp dizini oluşturuluyor..."
    New-Item -ItemType Directory -Path "C:\temp" | Out-Null
    Log "C:\temp dizini başarıyla oluşturuldu."
} else {
    Log "C:\temp dizini zaten mevcut."
}

# Disk 1’i Online Hale Getir
Log "Disk 1 online hale getiriliyor..."
$diskpartScript = @"
select disk 1
online disk
exit
"@
Out-File -FilePath "C:\temp\online_disk.txt" -Force -Encoding ASCII -InputObject $diskpartScript
diskpart /s "C:\temp\online_disk.txt" | Out-String
Log "Disk 1 online hale getirildi."

# Volume 2 Üzerinde İşlem Yapmayı Deneyin
Log "Volume 2 üzerinde işlem yapılıyor..."
$diskpartScript = @"
select disk 1
select volume 2
attributes volume clear readonly
attributes volume clear hidden
assign letter=E
exit
"@
Out-File -FilePath "C:\temp\volume_2.txt" -Force -Encoding ASCII -InputObject $diskpartScript
$volume2Output = diskpart /s "C:\temp\volume_2.txt" | Out-String

if ($volume2Output -match "Virtual Disk Service error") {
    Log "Volume 2 işleminde hata oluştu. Volume 3 üzerinde işlem deneniyor..."
    
    # Volume 3 Üzerinde İşlem Yap
    $diskpartScript = @"
select disk 1
select volume 3
attributes volume clear readonly
attributes volume clear hidden
assign letter=E
exit
"@
    Out-File -FilePath "C:\temp\volume_3.txt" -Force -Encoding ASCII -InputObject $diskpartScript
    $volume3Output = diskpart /s "C:\temp\volume_3.txt" | Out-String
    
    if ($volume3Output -match "Virtual Disk Service error") {
        LogError "Volume 3 üzerinde de işlem başarısız oldu!"
    } else {
        Log "Volume 3 başarıyla işlendi ve E: olarak atandı."
    }
} else {
    Log "Volume 2 başarıyla işlendi ve E: olarak atandı."
}

# E: Diskinde Boot Dosyalarını Ayarla
Log "E: diski için boot dosyaları ayarlanıyor..."
bcdboot E:\Windows /s E: /f ALL
if ($LASTEXITCODE -ne 0) {
    LogError "E: diski için boot dosyaları ayarlanamadı!"
}
Log "E: diski için boot dosyaları başarıyla ayarlandı."

# System Partition (Partition 2) için Letter Atama
Log "System Partition (Partition 2) için S: atanıyor..."
$diskpartScript = @"
select disk 1
select partition 2
assign letter=S
exit
"@
Out-File -FilePath "C:\temp\partition.txt" -Force -Encoding ASCII -InputObject $diskpartScript
diskpart /s "C:\temp\partition.txt" | Out-String
Log "System Partition için S: başarıyla atandı."

# S: Diskine Boot Dosyalarını Ayarla
Log "S: diski için boot dosyaları ayarlanıyor..."
bcdboot E:\Windows /s S: /f UEFI
if ($LASTEXITCODE -ne 0) {
    LogError "S: diski için boot dosyaları ayarlanamadı!"
}
Log "S: diski için boot dosyaları başarıyla ayarlandı."

Log "Tüm işlemler başarıyla tamamlandı!"
