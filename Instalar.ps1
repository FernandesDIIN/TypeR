$ErrorActionPreference = 'Stop'
$staging = $null
$backup = $null
$dest = $null
try {
 if (Get-Process Photoshop -ErrorAction SilentlyContinue) { throw 'Feche o Photoshop antes de instalar.' }
 $extensions = Join-Path $env:APPDATA 'Adobe\CEP\extensions'
 $matches = @(Get-ChildItem -LiteralPath $extensions -Directory | Where-Object {
  $manifestPath = Join-Path $_.FullName 'CSXS\manifest.xml'
  if (Test-Path -LiteralPath $manifestPath) {
   [xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
   @($manifest.ExtensionManifest.ExtensionList.Extension | Where-Object { $_.Id -eq 'typer' }).Count -gt 0
  } else { $false }
 })
 if ($matches.Count -ne 1) { throw 'Não foi encontrada uma única instalação do TypeR no usuário atual. Não houve alteração. Confira Adobe\CEP\extensions em APPDATA.' }
 $dest = $matches[0].FullName
 [xml]$current = Get-Content -LiteralPath (Join-Path $dest 'CSXS\manifest.xml') -Raw
 $version = @($current.ExtensionManifest.ExtensionList.Extension | Where-Object { $_.Id -eq 'typer' })[0].Version
 if ($version -ne '2.5.0') { throw "Esta adaptação requer TypeR 2.5.0. Versão encontrada: $version." }
 $backupRoot = Join-Path $env:APPDATA 'TypeR-MultiPaginas\Backups'
 New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
 $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
 $staging = Join-Path $backupRoot ('preparando-'+$stamp)
 $backup = Join-Path $backupRoot ('original-'+$stamp)
 Copy-Item -LiteralPath $dest -Destination $staging -Recurse
 foreach ($folder in @('app','CSXS','icons','locale')) {
  $source = Join-Path $PSScriptRoot ('TypeR_Personalizado\'+$folder)
  if (!(Test-Path -LiteralPath $source)) { throw 'Extraia o ZIP inteiro antes de instalar.' }
  $target = Join-Path $staging $folder
  if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
  Copy-Item -LiteralPath $source -Destination $target -Recurse
 }
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'TypeR_Personalizado\VERSAO.json') -Destination (Join-Path $staging 'VERSAO.json') -Force
 foreach ($cepVersion in @(9,10,11,12)) {
  $reg = 'HKCU:\Software\Adobe\CSXS.' + $cepVersion
  New-Item -Path $reg -Force | Out-Null
  New-ItemProperty -Path $reg -Name PlayerDebugMode -Value '1' -PropertyType String -Force | Out-Null
 }
 Move-Item -LiteralPath $dest -Destination $backup
 try { Move-Item -LiteralPath $staging -Destination $dest; $staging=$null }
 catch { Move-Item -LiteralPath $backup -Destination $dest; throw }
 Write-Host 'Instalado. Abra Janela > Extensões (herdadas) > TypeR Personalizado.' -ForegroundColor Green
 Write-Host 'Estilos e configurações existentes foram preservados.'
 Write-Host "Cópia da instalação anterior: $backup"
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Recurse -Force } }
