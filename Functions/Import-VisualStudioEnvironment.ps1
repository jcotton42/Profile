function Import-VisualStudioEnvironment {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Alias("VSVersion", "Version")]
        [string] $VisualStudioVersion = "2017",

        [ValidateSet("x86", "amd64", "arm", "arm64")]
        [Alias("arch")]
        [string] $Architecture = "amd64",

        [ValidateSet("x86", "amd64")]
        [Alias("host_arch")]
        [string] $HostArchitecture = "amd64",

        [ValidateSet("Desktop", "UWP")]
        [Alias("app_platform")]
        [string] $AppPlatform = "Desktop",

        [string] $Edition = "Enterprise"
    )

    $batArgs = (
        "-arch=$Architecture",
        "-host_arch=$HostArchitecture",
        "-app_platform=$AppPlatform",
        "-no_logo"
    )
    cmd /c "C:\Program Files (x86)\Microsoft Visual Studio\$VisualStudioVersion\$Edition\Common7\Tools\VsDevCmd.bat" @batArgs `& set |
        where { $_ -match '=' } |
        foreach {
            $name, $value = $_ -split '=', 2
            Set-Content "Env:\$name" $value
        }
}
