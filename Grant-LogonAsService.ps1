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
