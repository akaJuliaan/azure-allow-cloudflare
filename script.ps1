# Login in Azure (you may need to give the system account more permission)
"Logging in to Azure..."
Connect-AzAccount -Identity

# Fetch Cloudflare IPv4 and IPv6 ranges
$cloudflareIPv4 = (Invoke-RestMethod -Uri "https://www.cloudflare.com/ips-v4") -split '\r?\n'
$cloudflareIPv6 = (Invoke-RestMethod -Uri "https://www.cloudflare.com/ips-v6") -split '\r?\n'

# Combine IPv4 and IPv6 ranges
$combinedCloudflareIPs = $cloudflareIPv4 + $cloudflareIPv6

# Azure NSG details
$resourceGroupName = "your_ressource_group"
$nsgName = "your_nsg_name"

# Define a naming convention for Cloudflare rules
$ruleNamePrefix = "Allow-From-Cloudflare"

# Get existing NSG rules
$existingRules = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName | Get-AzNetworkSecurityRuleConfig

# Get the NSG object
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName

# Remove existing Cloudflare rules
$existingRules = $existingRules | Where-Object { $_.Name -like "$ruleNamePrefix-*" }
foreach ($rule in $existingRules) {
    Remove-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $rule.Name
}

# Add NSG rule for Cloudflare IPv4 addresses allowing only ports 80 and 443
$priority = 100
$ruleNameIPv4 = "$ruleNamePrefix-IPv4"
$ruleConfigIPv4 = New-AzNetworkSecurityRuleConfig -Name $ruleNameIPv4 -Priority $priority -SourceAddressPrefix $cloudflareIPv4 -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '80','443' -Protocol 'TCP' -Access Allow -Direction Inbound

# Add NSG rule for Cloudflare IPv6 addresses allowing only ports 80 and 443
$priority++
$ruleNameIPv6 = "$ruleNamePrefix-IPv6"
$ruleConfigIPv6 = New-AzNetworkSecurityRuleConfig -Name $ruleNameIPv6 -Priority $priority -SourceAddressPrefix $cloudflareIPv6 -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '80','443' -Protocol 'TCP' -Access Allow -Direction Inbound

# Add the rule configurations to NSG
$nsg.SecurityRules += $ruleConfigIPv4
$nsg.SecurityRules += $ruleConfigIPv6

# Apply the updated NSG configuration
$nsg | Set-AzNetworkSecurityGroup
