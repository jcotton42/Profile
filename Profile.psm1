. "$PSScriptRoot\AllHosts.ps1"

$Script:hostProfile = Split-Path $profile.CurrentUserCurrentHost -Leaf
if(Test-Path "$PSScriptRoot\$Script:hostProfile") {
    . "$PSScriptRoot\$Script:hostProfile"
}

foreach($script in Get-ChildItem "$PSScriptRoot\Functions") {
    . $script.FullName
}
