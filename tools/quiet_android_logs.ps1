param(
  [string]$DeviceId = ""
)

$adb = "C:\Users\CH-COA\AppData\Local\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
  throw "adb not found at $adb"
}

$targetArgs = @()
if ($DeviceId -ne "") {
  $targetArgs = @("-s", $DeviceId)
}

& $adb @targetArgs shell setprop log.tag.Adreno-AppProfiles S | Out-Null
& $adb @targetArgs shell setprop log.tag.ashmem S | Out-Null
& $adb @targetArgs shell setprop "log.tag.eenlab.app2.dev" S | Out-Null

Write-Output "Applied Android log filters for noisy native startup warnings."
