targetScope = 'subscription' // Please Update this based on deploymentScope Variable

//
// Imported Parameters

@description('Azure Location')
param location string

@description('Azure Location Short Code')
param locationShortCode string

@description('Environment Type')
param environmentType string

@description('User Deployment Name')
param deployedBy string

@description('Azure Metadata Tags')
param tags object = {
  environmentType: environmentType
  deployedBy: deployedBy
  deployedDate: utcNow('yyyy-MM-dd')
}

//
// Bicep Deployment Variables

var resourceGroupName = 'rg-devops-agent-${environmentType}-${locationShortCode}'

//
// Azure Verified Modules - No Hard Coded Values below this line!

module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'create-resource-group'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module createUserManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'create-user-managed-identity'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'id-devops-agent-${environmentType}-${locationShortCode}'
    location: location
    tags: tags
  }
  dependsOn: [
    createResourceGroup
  ]
}

module createAzureComputeGallery 'br/public:avm/res/compute/gallery:0.8.2' = {
  name: 'create-azure-compute-gallery'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'gal1devopsagents${locationShortCode}'
    location: location
    images:[
      {
      identifier: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '24_04-lts'
      }
      osType: 'Linux'
      osState: 'Generalized'
      name: 'devops-ubuntu-2404'
      hyperVGeneration: 'V2'
      securityType: 'TrustedLaunch'
      }
    ]
    roleAssignments: [
      {
        principalId: createUserManagedIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor Role
      }
    ]
  }
  dependsOn: [
    createResourceGroup
  ]
}

module createBuildImageTemplate 'br/public:avm/res/virtual-machine-images/image-template:0.4.2' = {
  name: 'create-build-image-template'
  scope: resourceGroup(resourceGroupName)

  params: {
    name: 'devops-ubuntu-2404'
    location: location

    distributions: [
      {
        type: 'SharedImage'
        sharedImageGalleryImageDefinitionResourceId: createAzureComputeGallery.outputs.imageResourceIds[0]
        sharedImageGalleryImageDefinitionTargetVersion: '1.0.0'
      }
    ]

    osDiskSizeGB: 127
    vmSize: 'Standard_B2s'

    imageSource: {
      offer: 'ubuntu-24_04-lts'
      publisher: 'canonical'
      sku: 'server'
      type: 'PlatformImage'
      version: 'latest'
    }

    managedIdentities: {
      userAssignedResourceIds: [
        createUserManagedIdentity.outputs.resourceId
      ]
    }

    customizationSteps: [
      {
        name: 'Update System Packages'
        type: 'Shell'
        inline: [
          'sudo apt update'
          'sudo apt dist-upgrade -y'
        ]
      }
      {
        name: 'Reboot System'
        type: 'Shell'
        inline: [
          'reboot'
        ]
      }
      {
        name: 'Install PowerShell'
        type: 'Shell'
        inline: [
          'wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb'
          'sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb'
          'sudo apt update && sudo apt install -y powershell'
        ]
      }
      {
        name: 'Install Azure CLI'
        type: 'Shell'
        inline: [
          'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'
        ]
      }
      {
        name: 'Install Azure Bicep'
        type: 'Shell'
        inline: [
          'az bicep install'
        ]
      }
      {
        name: 'Install AzCopy'
        type: 'Shell'
        inline: [
          'wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb'
          'sudo dpkg -i packages-microsoft-prod.deb'
          'rm packages-microsoft-prod.deb'
          'sudo apt update'
          'sudo apt install -y azcopy'
        ]
      }
    ]
  }

  dependsOn: [
    createAzureComputeGallery
  ]
}
