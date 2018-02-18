<#  
    Nintex Workflow History List Cleanup

    The purpose of this script is to leverage SharePoint's ProcessBatchData
    function to clean up the Nintex workflow history list when it has grown
    to larger sizes.
#>

$url = "http://server.local/sites/SOP"
$dryrun = $true  # If this variable is $NULL or $FALSE, it will assume you
                 # want to delete. Set to $TRUE to only report back the number
                 # of items that will be deleted.
$workflowStatus = "Error"  # Set this to define which workflow status to purge.
                           # Valid options: Canceled, Complete, Error
$bachAction = "Delete"

# Main Scriptblock
Write-Host "Connecting to SharePoint..."
$web = Get-SPWeb $url
Write-Host "Grabbing list..."
$list = $web.Lists['NintexWorkflowHistory']
Write-Host "Building query..."
$query = New-Object Microsoft.SharePoint.SPQuery
$query.ViewAttributes = "Scope='Recursive'"
$query.RowLimit = 2000;
$query.Query = "<Where><Eq><FieldRef Name='Outcome'></FieldRef><Value Type='Text'>" + $workflowStatus + "</Value></Eq></Where>"
Write-Host "Query built!"

$itemCount = 0
$listID = $list.Id
[System.Text.StringBuilder]$batchData = New-Object "System.Text.StringBuilder"
$batchData.Append("<?xml version=`"1.0`" encoding=`"UTF-8`"?><Batch>")
$cmd = [System.String]::Format( "<Method><SetList>{0}</SetList><SetVar Name=`"ID`">{1}</SetVar><SetVar Name=`"Cmd`">Delete</SetVar></Method>", $listId, "{0}" );
While($query.ListItemCollectionPosition -ne $NULL)
{
    $listItems = $list.GetItems($query)
    $query.ListItemCollectionPosition = $listItemsCollectionPosition
    ForEach($item in $listItems)
    {
        If($item -ne $NULL)
        {
            $batchData.Append([System.String]::Format($cmd, $item.ID.ToString())) | Out-Null
            $itemCount++
        }
    }
}
$batchData.Append("</Batch>")
Write-Host "Batch XML data created with $itemCount item(s)"
If($dryRun -eq $TRUE)
{
    Write-Host "`$dryRun is set to TRUE. If it were not set or $FALSE, I'd delete $itemCount item(s)"
}
Else
{
    Write-Host "Deleting $itemCount item(s)."
    [xml]$result = $web.ProcessBatchData($batchData.ToString())
}
Write-Host "Process completed."
$web.Dispose()
