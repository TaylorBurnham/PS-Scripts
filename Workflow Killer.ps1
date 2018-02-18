<#

                     Workflow Killer

    This script will take an SPListItem, terminate the Nintex workflow,
    re-inherit permissions (if needed), then move on to the next item.

#>

Function Reset-Document($SPListItem)
{
    $Workflow = ($SPListItem.Workflows | Where-Object {$_.InternalState -like '*Running*'})
    Write-Host "Terminating workflow instance $($Workflow.InstanceID)"
    [Microsoft.SharePoint.Workflow.SPWorkflowManager]::CancelWorkflow($Workflow)
    Write-Host "Canceled workflow -- pausing."
    Start-Sleep 1
    If($SPListItem.HasUniqueRoleAssignments -eq $TRUE)
    {
        Write-Host "Reinheriting permissions..."
        $SPListItem.ResetRoleInheritance()
    }
    Else
    {
        Write-Host "Permissions correct."
    }
    Write-Host "Applying changes..."
    $SPListItem.SystemUpdate()
    Write-Host "Done!"
}

