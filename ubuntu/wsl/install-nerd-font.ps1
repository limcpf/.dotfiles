# Windows PowerShell에서 실행합니다. WSL에서 호출하는 방법은 README에 있습니다.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$lockFile = Join-Path $PSScriptRoot '..\locks\versions.env'
$versions = @{}
Get-Content -LiteralPath $lockFile | ForEach-Object {
    if ($_ -match '^([A-Z_]+)=(.+)$') { $versions[$Matches[1]] = $Matches[2].Trim() }
}
$workDir = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-font-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workDir | Out-Null
try {
    $zip = Join-Path $workDir 'CascadiaCode.zip'
    $url = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v{0}/{1}' -f $versions.NERD_FONTS_VERSION, $versions.NERD_FONTS_ARCHIVE
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
    $digest = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($digest -ne $versions.NERD_FONTS_SHA256) { throw 'Nerd Font SHA256이 versions.env와 일치하지 않습니다.' }
    $expanded = Join-Path $workDir 'expanded'
    Expand-Archive -LiteralPath $zip -DestinationPath $expanded
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    $registry = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (-not (Test-Path -LiteralPath $registry)) {
        New-Item -Path $registry | Out-Null
    }
    if (-not ('DotfilesFonts' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DotfilesFonts {
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern int AddFontResourceEx(string path, uint flags, IntPtr reserved);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint msg, IntPtr wparam, IntPtr lparam, uint flags, uint timeout, out IntPtr result);
}
'@
    }
    $fonts = Get-ChildItem -LiteralPath $expanded -Recurse -Filter '*.ttf'
    if ($fonts.Count -eq 0) { throw '압축 파일에 TTF 글꼴이 없습니다.' }
    foreach ($font in $fonts) {
        $target = Join-Path $fontDir $font.Name
        Copy-Item -LiteralPath $font.FullName -Destination $target -Force
        New-ItemProperty -Path $registry -Name $font.BaseName -Value $target -PropertyType String -Force | Out-Null
        [DotfilesFonts]::AddFontResourceEx($target, 0, [IntPtr]::Zero) | Out-Null
    }
    $result = [IntPtr]::Zero
    [DotfilesFonts]::SendMessageTimeout([IntPtr]0xffff, 0x001d, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result) | Out-Null
    Write-Output ('글꼴 {0}개 설치 완료. 선택할 글꼴: CaskaydiaCove Nerd Font Mono' -f $fonts.Count)
} finally {
    # 이번 실행에서 만든 고유 임시 디렉터리만 정리합니다.
    if ((Split-Path -Leaf $workDir) -like 'dotfiles-font-*') {
        Remove-Item -LiteralPath $workDir -Recurse -Force
    }
}
