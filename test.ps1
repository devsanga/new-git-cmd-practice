param (
    [string]$jsonFilePath,
    [string]$keyFilePath
)

# Import the decryption module
Import-Module ".\DecryptModule.psm1"

# Load the JSON data
$jsonData = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Decrypt the password using the decryption function from the module
$decryptedPassword = retrievePlainString -encryptedString $jsonData.password -keyFilePath $keyFilePath

# Iterate over nodes and services
foreach ($node in $jsonData.nodes) {
    foreach ($service in $jsonData.services) {
        Write-Host "Updating service '$service' on node '$node' with user '$($jsonData.username)'"
        
        # Command to update the service logon account
        # (Example using 'sc.exe' to update service credentials)
        Invoke-Command -ComputerName $node -ScriptBlock {
            param($serviceName, $username, $password)
            sc.exe config $serviceName obj= $username password= $password
        } -ArgumentList $service, $jsonData.username, $decryptedPassword
    }
}
