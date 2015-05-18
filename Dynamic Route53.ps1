# Hosted Zone ID
$HostedZoneID = '<HostedZoneID>'
# URL to update -- including the trailing '.'
$RecordName = 'some.subdomain.at.burnham.io.'
# Record Type
$RecordType = 'A'
# AWS Credential Profile Name
$Credentials = 'AWS Credential Store Name'

# Initialize the necessary modules
Import-Module AWSPowerShell
# Set up the credentials
Set-AWSCredentials -ProfileName $Credentials
# Get your IP address
Write-Host "Getting public IP address..."
$PublicIP = (New-Object System.Net.WebClient).DownloadString("http://ifconfig.me/ip").Trim()
Write-Host "Getting resource records for $HostedZoneID"
$ResourceRecords = Get-R53ResourceRecordSet -HostedZoneId $HostedZoneID
$RecordSet = $ResourceRecords.ResourceRecordSets | Where-Object {$_.Name -eq $RecordName -AND $_.Type -eq $RecordType}
$RecordValue = $RecordSet.ResourceRecords[0].Value.Trim()
Write-Host "Current Value: $RecordValue"
Write-Host "Desired Value: $PublicIP"
If($RecordValue -ne $PublicIP)
{
    Write-Host "Records don't match." -ForegroundColor Red
    $Action = New-Object -TypeName Amazon.Route53.Model.Change
    $Action.Action = "DELETE"
    $Action.ResourceRecordSet = $RecordSet
    Write-Host "Deleting old record."
    $Change = Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneID -ChangeBatch_Change $Action
    Write-Host "Allowing change to be applied."
    Start-Sleep -Seconds 10
    $NewRecordSet = New-Object -TypeName Amazon.Route53.Model.ResourceRecordSet
    $NewRecordSet.Name = $RecordName
    $NewRecordSet.Type = $RecordType
    $NewRecordSet.TTL = $RecordSet.TTL
    $NewRecordSet.ResourceRecords.Add($PublicIP)
    $Action = New-Object -TypeName Amazon.Route53.Model.Change
    $Action.Action = "CREATE"
    $Action.ResourceRecordSet = $NewRecordSet
    Write-Host "Adding new record..."
    $Change = Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneID -ChangeBatch_Change $Action
    Write-Host "Completed." -ForegroundColor Green
}
Else
{
    Write-Host "Records match!" -ForegroundColor Green
}
