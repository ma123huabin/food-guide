param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$geoResult = $null
$watcher = $null
try {
    Add-Type -AssemblyName System.Device
    $watcher = New-Object System.Device.Location.GeoCoordinateWatcher -ArgumentList ([System.Device.Location.GeoPositionAccuracy]::High)
    $ready = $watcher.TryStart($false, [TimeSpan]::FromSeconds(16))
    if ($watcher.Permission -eq [System.Device.Location.GeoPositionPermission]::Denied) {
        $geoResult = @{error='系统未允许位置访问，请在 Windows 设置中开启定位服务及桌面应用位置权限。'}
    } elseif (!$ready -or $watcher.Position.Location.IsUnknown) {
        $geoResult = @{error='未获取到设备位置。请在 Windows 设置中开启定位服务，再重试。'}
    } else {
        $geoResult = @{lat=$watcher.Position.Location.Latitude; lng=$watcher.Position.Location.Longitude; accuracy=$watcher.Position.Location.HorizontalAccuracy}
    }
} catch {
    $geoResult = @{error='此设备的 Windows 定位服务不可用。请开启系统定位，或使用支持定位的浏览器版本。'}
} finally {
    if ($null -ne $watcher) { $watcher.Stop(); $watcher.Dispose() }
}
$geoJson = ConvertTo-Json -InputObject $geoResult -Compress
$geoTemporary = $OutputPath + '.pending'
[System.IO.File]::WriteAllText($geoTemporary, $geoJson, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::Move($geoTemporary, $OutputPath)
