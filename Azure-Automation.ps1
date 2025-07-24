# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Test-SqlServerAdminUsername ensures that the SQL Server Admin does not contain the following:
        - Your login name must not contain a SQL Identifier or a typical system name (like admin, administrator, sa, root, dbmanager, loginmanager, etc.) or a built-in database user or role (like dbo, guest, public, etc.)
        - Your login name must not include non-alphanumeric characters
        - Your login name must not start with numbers or symbols
#>
function Test-SqlServerAdminUsername {
    param ([string]$Username)

    $prohibitedUsernames = @("admin", "administrator", "sa", "root", "dbmanager", "loginmanager", "dbo", "guest", "public")
    
    for ($i = 0; $i -lt $prohibitedUsernames.Count; $i++) {
        if($Username -like $prohibitedUsernames[$i])
        {
            Write-Host "[x] SQL Server admin username cannot contain an SQL Identifier (e.g. admin) or typical system name (e.g. root)..."
            return $false
        }
    }

    $Username = $Username.Trim()

    if($Username -match "\W")
    {
        Write-Host "[x] SQL Server admin username cannot contain non-alphanumerical chars..."
        return $false
    }

    if($Username[0] -like "[0-9]")
    {
        Write-Host "[x] SQL Server admin username cannot start with numbers..."
        return $false
    }
    return $true
}

# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Test-SqlServerAdminPassword ensures that the SQL Server Admin does not contain the following:
        - Your password must be at least 8 characters in length.
        - Your password must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9) x, and non-alphanumeric characters (!, $, #, %, etc.) x.
#>
function Test-SqlServerAdminPassword {
    param ([string]$Password)

    $minLength = 8
    $passwordLength = $Password.Length
    $containsDigit = $Password -match "\d{1}"
    $containsUpperCaseChar = $Password -cmatch "[A-Z]"
    $containsLowerCaseChar = $Password -match "[a-z]"
    $containsSpecialChar = $Password -match "\W"

    if($passwordLength -lt $minLength)
    {
        Write-Host "[x] SQL Server admin password needs to be greater than or equal to 8 chars in length..."
        return $false
    }

    if(!$containsDigit)
    {
        Write-Host "[x] SQL Server admin password must contain numbers (0-9)..."
        return $false
    }

    if(!$containsSpecialChar)
    {
        Write-Host "[x] SQL Server admin password must contain a non-alphanumeric char (e.g. @#,)..."
        return $false
    }

    if(!$containsUpperCaseChar)
    {
        Write-Host "[x] SQL Server admin password must contain uppercase letters..."
        return $false
    }

    if(!$containsLowerCaseChar)
    {
        Write-Host "[x] SQL Server admin password must contain lowercase letters..."
        return $false
    }
    return $true
}

# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Connects to Azure with an authenticated account, if authentication is cancelled the script will terminate.
#>
$context = Connect-AzAccount

if(!$context)
{
    exit
}

# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Obtains student number, that meets the REGEX. The student number variable is necessary for appserviceplanname and resourcegroupname
    as both reference it.
#>

$studentNumber 

while ($true) {
    $studentNumber = Read-Host -Prompt "[-] Enter student number"

    if($studentNumber -like "ST[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")
    {
        Write-Host "[+] Student number saved..." 
        break
    }
    else {
        Write-Host "[x] Student number is in incorrect format..."
    } 
}

$sqlServerAdminUsername

while ($true) 
{
    $sqlServerAdminUsername = Read-Host -Prompt "[-] Enter SQL Server admin username"

    if (Test-SqlServerAdminUsername -Username $sqlServerAdminUsername) {
        Write-Host "[+] Server admin username saved..."
        break
    }
}

$sqlServerAdminPassword

while($true)
{
    $sqlServerAdminPassword = Read-Host -Prompt "[-] Enter SQL Server admin password"

    if(Test-SqlServerAdminPassword -Password $sqlServerAdminPassword)
    {
        Write-Host "[+] Server admin password saved..."
        break
    }
}

# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Creates the Azure Web App service using New-AzWebApp cmdlet with the below parameters:
        -Name =>  The name of the Web App service, which uses the student number to ensure the correct format: stxxxxxxxx.azurewebsites.net
        -Location => The location of the Azure Web App service (e.g. southafricaNorth)
        -ResourceGroupName => The name of the resource group name, this can be found on the Azure portal (however is student specific)
        -AppServicePlan => The App Service Plan Name, this can be found on the Azure portal (however is student specific)
    
    Modifies the Azure Web App service using Set-AzWebApp cmdlet with the below parameters;
        -Name => References the webapp name for identification purposes
        -ResourceGroupName => References the resource group name for identification purposes
        -AppServicePlan => Refereneces the app service plan name for identification purposes 
        -NetFrameworkVersion => Sets the enviroment stack to .NET 8 (LTS)
#>

# Web service params
$appServicePlanName = "ASP-AZJHBRSGVCWCCN" + $studentNumber.ToUpper() + "TER-b1d5"
$resourceGroupName = "AZ-JHB-RSG-VCWCCN-" + $studentNumber.ToUpper() + "-TER"
$location = "southafricaNorth"

try {
    Write-Host "[+] Attempting Azure Web App service creation and deployment..."
    # Creates the Web app service
    New-AzWebApp -Name $studentNumber.ToLower() -Location $location -AppServicePlan $appServicePlanName -ResourceGroupName $resourceGroupName 
    # Sets the runtime env to .NET 8 (LTS)
    Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $studentNumber.ToLower() -AppServicePlan $appServicePlanName -NetFrameworkVersion "8"
}
catch {
    Write-Host "[x] Cannot Deploy Azure web app service..."
    Write-Host $_
}

# ----------------------------------------------------------------------------------------------------------------------------------------//
<#
    Creates the Azure SQL Server using the New-AzSqlServer cmdlet with the below parameters:

        -ResourceGroupName => The name of the resource group name, this can be found on the Azure portal (however is student specific)
        -Location => The location of the Azure SQL Server (e.g. southafricaNorth)
        -ServerName => Specifies the servers name
        -PublicNetworkAccess => Takes a flag, enabled/disabled, to specify whether public network access to server is allowed or not. 
        -SqlAdministratorCredentials => Specifies the SQL Database server administrator credentials for the new server. 

    Configures the Firewall IPv4 address range (e.g. 1.0.0.0 - 255.255.255.254) using New-AzSqlServerFirewallRule cmdlet with the following parameters:

        -StartIpAddress => 1.0.0.0
        -EndIpAddress => 255.255.255.254 (This ensures the lecturer can access it...)

    Creates an SQL Database using the New-AzSqlDatabase cmdlet with the below parameters: 
        -ResourceGroupName => Used for identification purposes.
        -ServerName => Used for identification purposes.
        -DatabaseName => Used as a unique identifier for the database which is in the following format stxxxxxxxxdb
        -Edition => Speicifies the Service tier 'Basic'
#>

# SQL Server params
$publicNetworkAccess = "enabled"
$startIp = "1.0.0.0"
$endIp = "255.255.255.254"

# SQL Database params
$sqlDatabaseName = $studentNumber.ToLower() + "db"

try {
    Write-Host "[+] Attempting SQL server creation and deployment..."
    # Creates the SQL server 
    New-AzSqlServer -ResourceGroupName $resourceGroupName -Location $location -ServerName $studentNumber.ToLower() -PublicNetworkAccess $publicNetworkAccess -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlServerAdminUsername, $(ConvertTo-SecureString -String $sqlServerAdminPassword -AsPlainText -Force))
    Write-Host "[+] Setting SQL server Firewall IPv4 range..."
    # Configures the Firewall IPv4 address range (e.g. 1.0.0.0 - 255.255.255.254)
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $studentNumber.ToLower() -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
    Write-Host "[+] Creating database..."
    # Creates Azure SQL database
    New-AzSqlDatabase  -ResourceGroupName $resourceGroupName -ServerName $studentNumber.ToLower() -DatabaseName $sqlDatabaseName -Edition Basic -BackupStorageRedundancy Local
}
catch {
    Write-Host "[x] Cannot Deploy Azure SQL server..."
    Write-Host $_
}

# Disconnects Azure Account 
Disconnect-AzAccount


<# 
    The Azure Web App service can be configured further using the Set-AzWebApp cmdlet 
        https://learn.microsoft.com/en-us/powershell/module/az.websites/set-azwebapp?view=azps-14.2.0#-netframeworkversion

    However, it should be noted that the pricing tier does not need to be set, as the resource group determines it by default.

    Further information can be found below on the New-AzSqlServer cmdlet:
        https://learn.microsoft.com/en-us/powershell/module/az.sql/new-azsqlserver?view=azps-14.2.0

    Here is how the documentation describes the user of New-AzSqlDatabase:
        https://learn.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-powershell?view=azuresql
        https://learn.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-14.2.0
        https://learn.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-14.2.0#example-3-create-an-vcore-database-on-a-specified-server
    
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠛⠛⢉⢉⣉⣉⢉⣉⡉⠛⠛⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⣠⢴⣲⣞⡽⣯⠾⣜⣮⣛⡶⣭⣏⡷⣒⠦⡄⣈⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⡁⣴⣺⠝⠉⠈⠁⠉⠉⠉⠉⢿⣷⣿⣻⣷⣯⡟⠉⠁⠈⠈⠐⠂⠀⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⡿⢟⣉⠙⢿⣿⡿⠋⣠⣴⣻⡷⣿⣇⢀⣀⣠⣤⣤⣶⣶⣿⡿⣿⣽⣷⣻⣿⢶⣤⣤⣀⣀⠀⣰⢣⡄⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⠏⣤⣄⠈⢋⣴⣿⡿⠁⣸⠟⢀⣶⢯⣷⣿⣿⣿⣿⣿⡿⢿⡻⣽⢳⡯⣷⣟⣯⡿⣿⣳⣟⢯⡞⡵⠫⠝⣯⢳⡏⣾⡡⠌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⠀⣿⠟⠀⢸⣷⡌⠀⢐⣩⣤⡙⠻⣿⣿⣿⣿⣻⡟⢧⣛⢶⣳⢮⣗⣞⣦⠙⢞⣿⣟⠿⣼⢣⣟⣴⣃⠖⠀⠉⠚⠥⡻⠵⠗⠊⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⠀⣿⡷⠀⢸⣍⢠⠘⠿⠇⢿⣿⡷⠈⠿⠿⠟⠃⠉⠁⠀⠀⠀⠀⠀⠉⠘⠋⠌⢺⡯⣽⠾⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢺⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣆⢻⣤⡄⠘⠏⠘⠃⢀⣀⡄⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣾⣷⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⡏⣰⣿⡷⠀⠀⠀⢀⡈⠟⣁⣾⡿⠀⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡿⣿⡇⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⢁⣿⣿⣏⠀⠀⠀⣿⣿⣷⣿⠟⢁⣼⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⣿⣷⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⡏⢸⣿⣿⠇⠀⣾⠀⠻⠿⠟⣁⣴⣿⣿⣿⣷⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢼⣚⢿⣿⣷⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⡀⢤⣙⠉⠀⠀⣡⣴⠀⠲⣝⣻⡿⣿⡽⣯⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠐⠏⣻⢾⡭⠛⣾⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣶⣤⣥⣤⣤⣿⣿⠄⠘⣬⢳⣻⢵⠋⠉⠉⠉⢛⠋⠛⠷⠲⠶⣔⣶⣚⣛⡛⢟⣛⣻⡛⢏⠛⠙⠫⠑⢀⠀⠀⢀⢤⣤⡉⣿⠆⢀⣿⣿⣿⣿⣿⣿⣿⠟⠛⠻⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⢎⡱⣏⡾⣷⣿⣿⣶⣈⠻⠈⣷⣶⠐⣶⣶⣆⢰⣶⣶⠀⣶⣶⡆⢰⣶⠇⠸⠋⠀⣠⣟⡳⣞⡽⣹⠀⣸⣿⣿⣿⣿⣿⣿⡏⢰⣿⡆⢹⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠸⣝⡾⣽⣿⣽⡿⣿⣷⣤⡰⢮⢠⣭⣭⡍⣨⣭⣥⢀⣬⣥⡄⢴⣶⡆⢸⢋⣼⠓⢨⢷⣙⠾⠁⢠⣿⣿⣿⣿⣿⣿⣿⡇⢰⣶⡆⣾⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠁⢾⣹⢳⣯⣿⣻⣽⡞⢷⣿⣦⣍⠻⠿⣧⣿⣿⣿⠠⣿⣿⡇⡾⠟⢃⣴⠫⠂⣰⡛⣦⢋⠞⢠⣿⣿⣿⣿⣿⣿⣿⣿⠀⢼⣯⣄⢻⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠈⢞⡭⣟⡾⣯⢿⣽⣆⡘⠛⣿⣿⣶⣦⣤⣭⣍⣤⣩⣥⣤⡖⣯⡛⠂⣠⡞⢧⡙⡄⠃⣠⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀⠈⣉⣠⣉⣋⠛⢿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠙⢮⢳⡽⣻⣞⣿⣻⣷⣤⣈⠛⠳⠿⢟⡾⢷⡟⠞⠖⠙⣀⠴⡚⡵⢊⠇⠈⣀⣾⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠨⠀⠀⣽⣿⣿⣿⣿⡆⣹
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠁⡳⣓⢮⢳⡳⢮⡳⣏⣟⡳⢖⢦⡒⢦⡔⡲⢜⡹⢌⡣⠝⠐⠉⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⠆⠐⠀⡀⢠⣄⣠⣄⣀⠰⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣈⠈⠣⢙⢣⠳⡍⠶⣙⠞⢦⡙⢦⠓⡍⠎⠐⠃⢀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣎⠀⠀⢄⠈⢻⣿⣿⣿⣿⣿⣸
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣤⣤⣌⣁⣈⣈⣀⣁⣀⣤⣤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⢠⣦⣦⣭⣤⡹⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡘⠿⠿⠿⠿⢃⣿⣿
    Author: James Marshall (ST10434366)
#>