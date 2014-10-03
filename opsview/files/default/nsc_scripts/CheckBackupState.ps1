# CheckBackupState.ps1
# This PowerShell script checks Veeam backup state using custom attributes in vCenter
# VMware PowerCLI must be installed to use the 'VMware.VimAutomation.Core' snapin

# Parameters
# -vCenterServer          The FQDN of the vCenter Server to connect to
# -vCenterUser            The username for connecting to vCenter Server
# -vCenterPassword        The password for connecting to vCenter Server
# -BackupRange            The range in hours that a VM should be backed up in
# -BackupStateAttribute   The custom attribute to check for the VM's backup state
# -IgnoreStateAttribute   The custom attribute to determine if a VM's backup state should be ignored
# -ExcludedFolders        The backup state of VMs in the folders specified will not be checked

# Get command line parameters
Param (
  [string]$vCenterServer,
  [string]$vCenterUser,
  [string]$vCenterPassword,
  [int]$BackupRange = 24,
  [string]$BackupStateAttribute = "VeeamBackupState",
  [string]$IgnoreStateAttribute = "IgnoreBackupState",
  [array]$ExcludedFolders
)

# Use the PowerCLI snapin and connect to vCenter
Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $vCenterServer -Username $vCenterUser -Password $vCenterPassword | Out-Null

$OutdatedBackups = @()
$BackupRangeDate = (Get-Date).AddHours(-$BackupRange)

# Look at the backup state for all VMs
Get-VM | Sort Name | ForEach {
  if (!($ExcludedFolders -contains $_.Folder)) {
    # Get VM backup state from a custom attribute
    $VMBackupState = $_ | Get-Annotation -CustomAttribute $BackupStateAttribute
    $IgnoreBackupState = $_ | Get-Annotation -CustomAttribute $IgnoreStateAttribute

    # Ignore the VM if the attribute is set
    if (!($IgnoreBackupState.Value -eq 'True')) {
      if ($VMBackupState.Value) {
        # Check timestamp
        $LastBackedUp = $VMBackupState.Value -Replace '^.*\[(\d{1,2}\/\d{1,2}\/\d{4}.\d{1,2}:\d{2}:\d{2}.[AP]M).*$', '$1'
        # If the timestamp is outside of the time range, add it to the list of VMs with outdated backups
        if ([datetime]$LastBackedUp -lt $BackupRangeDate) {
          $OutdatedBackups += , @($_, $LastBackedUp)
        }
      }
      # If the backup state attribute is empty, the VM has never been backed up
      else {
        $OutdatedBackups += , @($_, "Never")
      }
    }
  }
}

if ($OutdatedBackups.count -gt 0) {
  Write-Output "WARNING: The following VMs have outdated backups:"
  ForEach ($VM in $OutdatedBackups) {
    Write-Output "$($VM[0]): $($VM[1])"
  }
  Exit 1
}
else {
  Write-Output "OK: All virtual machines have current backups."
  Exit 0
}