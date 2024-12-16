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

function retrievePlainString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$encryptedString,

        [Parameter(Mandatory = $true)]
        [string]$salt = "default-secret-key"
    )

    # Convert the salt to a byte array (32 bytes)
    $saltBytes = [System.Text.Encoding]::UTF8.GetBytes($salt.PadRight(32).Substring(0, 32))

    try {
        # Decrypt the encrypted string
        $secureString = $encryptedString | ConvertTo-SecureString -Key $saltBytes -ErrorAction Stop
        $plainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                     )
        return $plainText
    } catch {
        Write-Output "Decryption failed for the provided string: $($_.Exception.Message)"
        return $null
    }
}