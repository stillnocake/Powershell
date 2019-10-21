$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file "C:\passwords\aes.key"


$key = get-content "C:\passwords\aes.key"
$encrypted = "ispasswordagoodpassword"|ConvertTo-SecureString -AsPlainText -Force
$EncyptedAES = $encrypted|ConvertFrom-SecureString -Key $key
$user = "JohnSmith"
$mycred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, ($EncyptedAES|ConvertTo-SecureString -key $key)


$mycred.GetNetworkCredential().Password
