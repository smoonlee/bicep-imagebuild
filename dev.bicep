param imageTemplates_azTemplateImage_name string = 'azTemplateImage'
param galleries_gal1devopsagentsweu_externalid string = '/subscriptions/b67e1026-b589-41e2-b41f-73f8803f71a0/resourceGroups/rg-devops-agent-dev-weu/providers/Microsoft.Compute/galleries/gal1devopsagentsweu'
param userAssignedIdentities_id_devops_agent_dev_weu_externalid string = '/subscriptions/b67e1026-b589-41e2-b41f-73f8803f71a0/resourceGroups/rg-devops-agent-dev-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-devops-agent-dev-weu'

resource imageTemplates_azTemplateImage_name_resource 'Microsoft.VirtualMachineImages/imageTemplates@2024-02-01' = {
  name: imageTemplates_azTemplateImage_name
  location: 'westeurope'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/b67e1026-b589-41e2-b41f-73f8803f71a0/resourceGroups/rg-devops-agent-dev-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-devops-agent-dev-weu': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 0
    customize: [
      {
        inline: [
          'sudo apt update && sudo apt dist-upgrade -y'
        ]
        name: 'Update System Packages'
        type: 'Shell'
      }
      {
        inline: [
          'sudo apt-get update && sudo apt-get install -y wget apt-transport-https software-properties-common\nsource /etc/os-release\nwget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb\nsudo dpkg -i packages-microsoft-prod.deb  ; rm packages-microsoft-prod.deb\nsudo apt-get update ; sudo apt-get install -y powershell'
        ]
        name: 'Install PowerShell 7'
        type: 'Shell'
      }
      {
        inline: [
          'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'
        ]
        name: 'Install Azure CLI'
        type: 'Shell'
      }
      {
        inline: [
          '# Extract distribution and version from /etc/os-release\nDISTRO=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d \'"\')\nVERSION=$(grep ^VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d \'"\')\n\n# Use the extracted values in the curl command\ncurl -sSL -O https://packages.microsoft.com/config/$DISTRO/$VERSION/packages-microsoft-prod.deb\nsudo dpkg -i packages-microsoft-prod.deb ; rm packages-microsoft-prod.deb\nsudo apt-get update; sudo apt-get install azcopy\n'
        ]
        name: 'Install AzCopy'
        type: 'Shell'
      }
    ]
    distribute: [
      {
        artifactTags: {}
        excludeFromLatest: false
        galleryImageId: '${galleries_gal1devopsagentsweu_externalid}/images/dev0-subuntu'
        replicationRegions: [
          'westeurope'
        ]
        runOutputName: 'runOutputImageVersion'
        type: 'SharedImage'
      }
    ]
    source: {
      offer: 'ubuntu-24_04-lts'
      publisher: 'canonical'
      sku: 'server'
      type: 'PlatformImage'
      version: 'latest'
    }
    vmProfile: {
      osDiskSizeGB: 127
      userAssignedIdentities: [
        userAssignedIdentities_id_devops_agent_dev_weu_externalid
      ]
      vmSize: 'Standard_B2s'
    }
  }
}
