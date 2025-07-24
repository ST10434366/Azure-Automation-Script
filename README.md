<img width="446" height="502" alt="image" src="https://github.com/user-attachments/assets/186cc1e3-39c5-4d54-890c-b3b19a8a35cf" /># Azure Automation Script

Automates the creation, deployment and configuration of Azure Web App, SQL Server and Database services.

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

# 👾Ussage

Run the Powershell script as follows:
```ps1#
powershell -ExecutionPolicy ByPass -File <replace with filepath>
```
Sign into student account:
<img width="936" height="1042" alt="image" src="https://github.com/user-attachments/assets/6b8f738c-64a7-463b-8a48-7781ca553c23" />

Enter your student number: 
<img width="326" height="42" alt="image" src="https://github.com/user-attachments/assets/b23fa3bf-2773-46ff-b0c7-b5175303ff0b" />

Enter a username for the SQL Server admin:
<img width="296" height="16" alt="image" src="https://github.com/user-attachments/assets/ed67ca7f-6382-4a75-b754-4bfe8468f98e" />

Enter a password for the SQL Server admin:
<img width="296" height="20" alt="image" src="https://github.com/user-attachments/assets/78c3da2c-9130-41d4-ae6d-6fe2795c4033" />
