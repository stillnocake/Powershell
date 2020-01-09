function Get-MachineSID {
    param(
        [switch]
        $DomainSID
    )

    $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

    if ($DomainSID -or $IsDomainController) {
        $Domain = $WmiComputerSystem.Domain
        $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid | % { $_ }
        $ByteOffset = 0
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes), $ByteOffset
    }
    else {
        $LocalAccountSID = Get-WmiObject -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
        $MachineSID = ($p = $LocalAccountSID -split "-")[0..($p.Length - 2)] -join "-"
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    }
}

function Get-GroupNameBySidType {
    param([parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.Principal.WellKnownSidType]$SidType)
    begin {
        $sidDomain = Get-MachineSID -DomainSID
    }
    process {
        try {
            [System.Security.Principal.SecurityIdentifier] $sid = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $SidType, $null;
        }
        catch {
            [System.Security.Principal.SecurityIdentifier] $sid = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $SidType, $sidDomain;
        }
        $sid.Translate([System.Security.Principal.NTAccount])
    }
}   




$configValidInfraDSQ = @{
    Directories = @(
        (New-Object -TypeName psobject -Property @{					
                Path      = "D:\AuthnDonne"
                shared    = $true
                shareName = "AuthnDonne"
                access    = @(
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid)), `
                            1179817, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList ($($(New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")).Translate([System.Security.Principal.NTAccount]))), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    )            
                )
            }
        ),
        (New-Object -TypeName psobject -Property @{					
                Path      = "D:\Log\SRC"
                shared    = $false
                shareName = $null
                security  = @(
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid)), `
                            1, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            $($(New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")).Translate([System.Security.Principal.NTAccount]))), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_SupDev") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                131209, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    )           
                )
            }
        ),
        (New-Object -TypeName psobject -Property @{					
                Path      = "D:\Inetpub\Pr-PilotRoot"
                shared    = $false
                shareName = $null
                security  = @(
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid)), `
                            1, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            $($(New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")).Translate([System.Security.Principal.NTAccount]))), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_SupDev") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                131209, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_Appli") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                131209, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_SRC_DEV") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                00000000, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    )

                )
            }
        ),
        (New-Object -TypeName psobject -Property @{					
                Path      = "D:\Inetpub\Tr-GestDispRoot"
                shared    = $false
                shareName = $null
                security  = @(
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (Get-GroupNameBySidType -SidType ([System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid)), `
                            1, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            $($(New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")).Translate([System.Security.Principal.NTAccount]))), `
                            2032127, `
                        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                        ([System.Security.AccessControl.PropagationFlags]::None), `
                        ([System.Security.AccessControl.AccessControlType]::Allow)
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_SupDev") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                131209, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_Appli") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                131209, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    ),
                    (New-Object "System.Security.AccessControl.FileSystemAccessRule" `
                            -ArgumentList (
                            (New-Object System.Security.Principal.NTAccount("$($env:USERDOMAIN)", "GLPR_SRC_DEV") | % { $_.Translate([System.Security.Principal.NTAccount]) }), `
                                00000000, `
                            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), `
                            ([System.Security.AccessControl.PropagationFlags]::None), `
                            ([System.Security.AccessControl.AccessControlType]::Allow)
                        )
                    )
                )
            }
        )                
    )
}

$configValidInfraDSQ.Directories | ForEach-Object {
    Write-Host "Vérification du path pour $($_.Path)" -ForegroundColor Cyan
    if (Test-Path $_.Path) {
        Write-Host "Le path $($_.Path) existe" -ForegroundColor Green
        $foldSec = get-acl $_.Path | Select-Object -ExpandProperty Access
        $listCompare = Compare-Object -IncludeEqual -ReferenceObject $foldSec -DifferenceObject $_.access -Property FileSystemRights, IdentityReference, AccessControlType, InheritanceFlags, IsInherited
    
        Write-Host "Vérification des groupes pour $($_.Path)" -ForegroundColor Cyan

        foreach ($elem in $ListCompare) {
            if ($elem.SideIndicator -eq "==") {
                Write-Host "Les droits sur $($_.path) pour $($elem.IdentityReference) sont valides." -ForegroundColor green
            }
            else {
                Write-Host "Les droits sur $($_.path) pour $($elem.IdentityReference) sont différents ou absents." -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "Le path $($_.Path) n'existe pas" -ForegroundColor yellow
    }

}
