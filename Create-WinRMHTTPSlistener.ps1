<#
.SYNOPSIS
A script to create a WinRM listener based on HTTPS with an Self Signed Computercertificate.
It connects to the remote computer of your choice and creates a computercertificate. Then it creates the listener with that certificate. In the end it exports the certificate and imports it in the local "trusted People"
After this you can connect your Windows Admin Center to this computer over https 
.VERSION
1.00
.DATE
21-04-2024
.AUTHOR
André Moro
.HELP ME
If you have any suggestions, please leave a comment: https://github.com/axmoro/
#>

# Parameters
$DomainName = Read-Host "Which domain do you want to connect to?"
$RemoteServer = Read-Host "Which server do you want to connect to?"

# Create a self-signed certificate on the remote server
$CertificateScript = {
    $Fullname = [System.Net.Dns]::GetHostByName($env:computerName).HostName
    $Params = @{
        "DnsName"            = @("$Fullname")
        "CertStoreLocation"  = "Cert:\LocalMachine\My"
        "NotAfter"           = (Get-Date).AddMonths(6)
        "KeyAlgorithm"       = "RSA"
        "KeyLength"          = 2048
    }
    New-SelfSignedCertificate @Params
}
Write-Host "Creating Certificate"
Invoke-Command -ComputerName $RemoteServer -ScriptBlock $CertificateScript

# Retrieve the thumbprint of the newly created certificate
$Thumbprint = Invoke-Command -ComputerName $RemoteServer -ScriptBlock {
    $Fullname = [System.Net.Dns]::GetHostByName($env:computerName).HostName
    Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.Subject -eq "CN=$Fullname" } | Select-Object -ExpandProperty Thumbprint
}
Write-Host "Thumbprint is $Thumbprint"

# Create the WinRM listener remotely
Write-Host "Creating WinRM Listener"
$ListenerScript = {
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $using:Thumbprint –Force
}
Invoke-Command -ComputerName $RemoteServer -ScriptBlock $ListenerScript

# Export the certificate from the remote server
Write-Host "Exporting Certificate Certificate"
$ExportPath = "C:\$RemoteServer.$domainName.cer"
Invoke-Command -ComputerName $RemoteServer -ScriptBlock {
    Export-Certificate -Cert "Cert:\LocalMachine\My\$using:Thumbprint" -FilePath $using:ExportPath -Type CERT
}
Write-Host "Certificate exported."

#Copy Certificate
Write-Host "Copying cert"
xcopy \\$Remoteserver\c$\$Remoteserver.$DomaiNname.cer c:\cert\

#Replace 'C:\Temp\RemoteServer.cer' with the actual path to your certificate file
$CertificatePath = "C:\cert\$Remoteserver.$DomainName.cer" 

#Import the certificate into the Trusted People store
Import-Certificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\TrustedPeople
Write-Host "Imported, you're done!"
