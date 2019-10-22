function Test-RemoteReg {
    param(  	[string][Parameter(mandatory = $true, ValueFromPipeline = $true)]$server,
        [string][Parameter(mandatory = $true, ValueFromPipeline = $true)]$key,
        [string][Parameter(mandatory = $true, ValueFromPipeline = $true)]$name
    )
    $type = [Microsoft.Win32.RegistryHive]::LocalMachine
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $server)
    $regKey = $reg.OpenSubKey($key)
    if ($regKey -eq $null) {
        Write-Error "$($server): $($regKey.GetValue($name))" -ErrorAction continue
    }
}
function Set-TNSNAME {
    param([string][Parameter(Mandatory = $true, ValueFromPipeline = $true)]$server)

    begin {
        $jobs = @()
    }

    process {
       
        #Invoke-Command -ScriptBlock{
        $job = Start-Job -ScriptBlock {
            param([string][Parameter(Mandatory = $true)]$server)
            Invoke-Command -ComputerName $server -ScriptBlock {
                param ([string][Parameter(Mandatory = $true)]
                    $server)
                function Get-PathEnvir {
                    $alphaEnvir = ($env:COMPUTERNAME -replace "(?:\w\d\w\d-)?(\w)\d{1,3}(\w)\d{3,4}(?:v|)", '$1')
                    $configEnvir = @{
                        P = ""
                        V = ""
                        T = ""
                    }
                    return ($configEnvir.$alphaEnvir)
                }
                function Get-ListeCleTNSADMIN {
                    $configReg = @{
                        key32 = "SOFTWARE\Wow6432Node"
                        key64 = "SOFTWARE"
                    }
					
                    $liste = @()
					
                    foreach ($key in $configReg.Keys) {
                        $liste += "Registry::HKEY_LOCAL_MACHINE\$($configReg.$key)\ORACLE\KEY_OraClient12Home1"
                        $liste += "Registry::HKEY_LOCAL_MACHINE\$($configReg.$key)\ORACLE\ODP.NET.Managed\4.122.1.0"
                        $liste += "Registry::HKEY_LOCAL_MACHINE\$($configReg.$key)\ORACLE\KEY_OraClient12Home1_32bit"
                    }
                    return $liste
                }
                function Set-TNSADMIN {
                    param ([parameter(mandatory = $true, valueFromPipeline = $true)]
                        $path,
                        [string]$name)
                    begin {
                        $value = Get-PathEnvir
                        $regEnvir = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
                        Write-Host $($env:ComputerName) -ForegroundColor Yellow
                        if (Test-Path $regEnvir) {
                            New-ItemProperty -Path $regEnvir -Name $name -Value $value -PropertyType String -Force | Out-Null
                            $item = Get-Item -Path $regEnvir
                            foreach ($prop in $item.Property) {
                                if ($prop -eq $name) {	
                                    $oldValue = (Get-ItemProperty -Path $regEnvir -Name $name).$name                                  
                                    Write-Host "`t $regEnvir : " # -NoNewline
                                    $newValue = (Get-ItemProperty -Path $regEnvir -Name $name).$name
                                    Write-Host "`t`t Old : $oldValue" -ForegroundColor Cyan
                                    Write-Host "`t`t New : $newValue" -ForegroundColor Green
                                }
                            }
                        }
                    }
                    process {
                        if (Test-Path $path) {
                            $item = Get-Item -Path $path
                            foreach ($prop in $item.Property) {
                                if ($prop -eq $name) {
                                    $oldValue = (Get-ItemProperty -Path $path -Name $name).$name
                                    Set-ItemProperty -Path $path -Name $name -Value $value
                                    Write-Host "`t $path : " # -NoNewline
                                    $newValue = (Get-ItemProperty -Path $path -Name $name).$name
                                    Write-Host "`t`t Old : $oldValue" -ForegroundColor Cyan
                                    Write-Host "`t`t New : $newValue" -ForegroundColor Green
                                }
                            }
                        }
                    }
					
                }
                function Remove-Folder {
                    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                        [String]$path)
					
                    process {
                        if (Test-Path -path $path) {
                            Write-Host -MessageData "Deletion of $path."
                            Remove-Item -Path $path -Recurse -Force
                        }
                    }
                }
				
				
                Get-ListeCleTNSADMIN | Set-TNSADMIN -name "TNS_ADMIN"
                @("\\$server\D$\Oracle", "\\$server\C$\Oracle\Client12c_64") | ForEach-Object {
                    if ((Test-Path $_) -and @(Get-ChildItem $_ | Where-Object { $_.Name -ne "network" } | Select-Object -first 1).Count -eq 0) {

                        Remove-Folder -path $_
                        
                    }
                }
                $oraFolder = "\\$server\C$\Oracle" 
                if (Test-Path -Path $oraFolder) {
                    if ((Get-ChildItem -Path $oraFolder ).Count -eq 0) {
                        Remove-Folder -path  $oraFolder
                    }    
                }   
            } -ArgumentList @($server)
        } -ArgumentList @($server)

        $jobs += $job
    
    }
    end {
        $jobs | Receive-Job -Wait
    }
}

function Test-PingComputer {
    param([string][Parameter(mandatory = $true, valueFromPipeline = $true)]$computer)
    $retValue = $false
    if (Test-Connection -ComputerName $computer -ErrorAction SilentlyContinue) {
        $retValue = $true
    }
    else {
        Write-Host "Server $computer offline."
        $retValue = $false
    }
    return $retValue
}


$servers = "$PSScriptRoot\servers.txt"
(Get-Content $servers) | Where-Object { $_.trim() -ne "" -and ((Test-PingComputer $_) -eq $true) } | Set-TNSNAME
