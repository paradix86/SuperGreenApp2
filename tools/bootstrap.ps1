$ErrorActionPreference = "Stop"

if (Get-Command flutter -ErrorAction SilentlyContinue) {
  $flutterBin = "flutter"
  $flutterPrefix = @()
} elseif (Get-Command fvm -ErrorAction SilentlyContinue) {
  $flutterBin = "fvm"
  $flutterPrefix = @("flutter")
} else {
  throw "Neither flutter nor fvm was found in PATH. Install Flutter 3.7.12 or fvm."
}

if (-not (Test-Path ".env")) {
  throw ".env not found. Copy .env.example to .env and fill the required values."
}

Write-Host "Installing Dart/Flutter packages..."
& $flutterBin @flutterPrefix pub get

Write-Host "Running code generation..."
& $flutterBin @flutterPrefix pub run build_runner build --delete-conflicting-outputs

Write-Host "Bootstrap completed."
