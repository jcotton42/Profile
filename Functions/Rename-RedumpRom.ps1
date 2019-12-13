function Rename-RedumpRom {
    <#
    Renames ROMs en masse based on data from redump.org
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        # Paths to ROM files
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [Alias('Path', 'PSPath')]
        [string[]] $RomPath,

        # Paths to dat files from redump.org
        [Parameter(Mandatory)]
        [SupportsWildcards()]
        [string[]] $RedumpDatPath
    )
    
    begin {
        $data = Get-Item $RedumpDatPath |
            ForEach-Object { ([xml](Get-Content $_)).datafile.game } |
            Group-Object { $_.rom.md5 } -AsHashTable -AsString
    }
    
    process {
        Get-Item $RomPath | ForEach-Object {
            $hash = (Get-FileHash -Path $_ -Algorithm MD5).Hash
            
            if($data.ContainsKey($hash)) {
                $name = $data[$hash].rom.name
                Rename-Item -Path $_ -NewName $name
            } else {
                Write-Warning "'$_' with MD5 hash '$hash' is not present in the redump data. Skipping."
            }
        }
    }
}
