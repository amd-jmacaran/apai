# Function to clone the runner-images repository
function Copy-Repository {
    [CmdletBinding(ConfirmImpact='None')]
    param (
        [string]$workingDirectory
    )
    Write-Output "Cloning https://github.com/actions/runner-images into $workingDirectory"
    git clone https://github.com/actions/runner-images
    exit
}

# Function to generate the specified image
function Add-Image {
    [CmdletBinding(SupportsShouldProcess=$false)]
    param (
        [string]$workingDirectory = $pwd,
        [string]$subscriptionId,
        [string]$tenantId = $env:tenantId,
        [string]$servicePrincipalId = $env:servicePrincipalId,
        [string]$servicePrincipalKey = $env:servicePrincipalKey,
        [string]$resourceGroupName,
        [string]$imageType,
        [string]$location,
        [string]$debugPacker
    )

    $verbosePreference = "Continue"
    Write-Output "Generate image $imageType in $resourceGroupName"
    Import-Module $workingDirectory\runner-images\helpers\GenerateResourcesAndImage.ps1
    Set-Location $workingDirectory\runner-images
    if ($debugPacker -eq 'true') {
        $env:PACKER_LOG = 1
    }
    GenerateResourcesAndImage `
        -SubscriptionId $subscriptionId `
        -ResourceGroupName $resourceGroupName `
        -ImageType $imageType `
        -AzureLocation $location `
        -AzureTenantId $tenantId `
        -AzureClientId $servicePrincipalId `
        -AzureClientSecret $servicePrincipalKey `
        -ReuseResourceGroup
}

# Function to update a VMSS with a new image
function Edit-VMSS {
    [CmdletBinding(ConfirmImpact='None')]
    param (
        [string]$resourceGroupName,
        [string]$resourceGroupNameImage,
        [string]$imageType
    )

    $currentSubscription = az account show --query 'id' -o tsv
    Write-Output "Current subscription: $currentSubscription"
    $imageID = "/subscriptions/$currentSubscription/resourceGroups/$resourceGroupNameImage/providers/Microsoft.Compute/images/Runner-Image-$imageType"
    Write-Output "Update VMSS Image in $resourceGroupName with image: $imageID"
    az vmss update `
        --resource-group $resourceGroupName `
        --name "apa-$imageType" `
        --set "virtualMachineProfile.storageProfile.imageReference.id=$imageID"
}
