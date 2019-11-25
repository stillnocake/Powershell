function Grant-LogOnAsService([string] $Username) {

    Write-Host "Enable ServiceLogonRight for $Username"
    $tmp = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg "$tmp.inf" | Out-Null
    get-content "$tmp.inf" | select-string "seservice"
    (gc -Encoding ascii "$tmp.inf") -replace '^SeServiceLogonRight .+', "`$0,$Username" | sc -Encoding ascii "$tmp.inf"
    secedit /import /cfg "$tmp.inf" /db "$tmp.sdb" | Out-Null
    secedit /configure /db "$tmp.sdb" /cfg "$tmp.inf" | Out-Null
    rm $tmp* -ea 0
}

$key = Get-Content "Key Location"
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $passw | ConvertTo-SecureString -Key $key)
Grant-LogOnAsService -Username $user | Out-Null

$proc = Start-Process "sc.exe" -ArgumentList "config ""$($configDynaServ.serviceName)"" obj= $($configDynaServ.$alphaPalier.dom)$($Credentials.GetNetworkCredential().UserName) password= $($Credentials.GetNetworkCredential().Password)" -Wait -PassThru


if ($proc.ExitCode -eq 0) {
    Get-service | Where-Object { ($_.Name -match "Service name") -and ($_.status -eq "Stopped" ) } | Start-Service
    Write-Log -Type Information -Text "Compte de service $($configDynaServ.$alphaPalier.user) configuré pour $($configDynaServ.serviceName)" -NoEventLog -Verbose
}
else {
    Write-Log -Type Information -Text "Service $($configDynaServ.serviceName) non configuré. Code de retour $($proc.ExitCode) " -NoEventLog -Verbose
}
