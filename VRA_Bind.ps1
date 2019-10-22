$server = Read-Host "Input server name: "
$user = ".\administrator"
#$pswd = ""
$pswd = Read-host -AsSecureString "Input local admin password: "
$creds = New-Object System.Management.Automation.PSCredential $user,$pswd

$configVRA = @{
    connect = ""
    line1 = "C:\VRMGuestAgent\WinService.exe -u;shutdown -r -t 00 -f"
    line2 = "C:\VRMGuestAgent\WinService.exe -i -h SERVERTOBINDTO -p ssl"
    restart = "Restart-Computer -Wait"
}

$cred = Get-Credential
Connect-VIServer $configVRA.connect -Credential $cred

Invoke-VMScript -VM $server -ScriptType Bat -ScriptText $configVRA.line1 -GuestUser $creds
Restart-Computer -ComputerName $server -Wait -For PowerShell -Delay 2
Invoke-VMScript -VM $server -ScriptType Bat -ScriptText $configVRA.line2 -GuestUser $creds
