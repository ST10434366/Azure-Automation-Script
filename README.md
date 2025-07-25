# Azure Automation Script

Automates the creation, and configuration of Azure Web App, SQL Server and Database services. In the future this will be extended to include storage services.

# 📋Dependencies 

- Az PowerShell module
- PowerShell version 7 or higher

# ⚙️Installation of Az PowerShell module

Run the following cmdlet in a PowerShell instance with administrator privileges to determine version.
Must be PowerShell version 7 or higher
```ps1#
$PSVersionTable.PSVersion
```

Check if you have the Azure PowerShell module installed already
```ps1#
Get-Module -Name AzureRM -ListAvailable
```

If not installed, set the PowerShell execution policy to remote signed or less restrictive
```ps1#
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Once execution policy is correctly set, run the following cmdlets:
```ps1#
Install-Module -Name Az -Repository PSGallery -Force
Update-Module -Name Az -Force
```

# 🔵Ussage 

Navigate to the directory that contains the `Azure-Automation.ps1` script, then run the following cmdlet: 

```ps1#
.\Azure-Automation.ps1 -bypass
```
