# Azure Automation Script

Automates the creation, deployment and configuration of Azure Web App, SQL Server and Database.

# 📋Dependencies 

- Az PowerShell module
- PowerShell version 7 or higher


# 📋Installation of Az PowerShell module

```ps1#

# Run the following command in a PowerShell instance with administrator privileges to determine version.
# Must be PowerShell version 7 or higher
$PSVersionTable.PSVersion

# Check if you have the Azure PowerShell module installed
Get-Module -Name AzureRM -ListAvailable

# If not installed, set the PowerShell execution policy to remote signed or less restrictive
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Once execution policy is currectly set, run the following commands:
Install-Module -Name Az -Repository PSGallery -Force
Update-Module -Name Az -Force

```

