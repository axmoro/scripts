<#
.SYNOPSIS
A script to copy the usergroups of a single user and apply these groups to the target user in Active Directory.
.VERSION
1.00
.DATE
22-11-2023
.AUTHOR
André Moro with help of BING AI
#>

# Prompt for source user
$userSource = Read-Host "Enter the source user (e.g., jsanti):"

# Prompt for target user
$userTarget = Read-Host "Enter the target user (e.g., a.adams):"

# Get the list of groups of the source user
$getusergroups = Get-ADUser –Identity $userSource -Properties memberof | Select-Object -ExpandProperty memberof

# Add the target user to the same groups
$getusergroups | Add-ADGroupMember -Members $userTarget -Verbose

# Verify group membership for the target user
Get-ADUser -Identity $userTarget -Properties memberof | Select-Object -ExpandProperty memberof
