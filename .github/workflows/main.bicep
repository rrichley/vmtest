param location string = resourceGroup().location
param vmAdminUsername string
@secure()
param vmAdminPassword string
param vmSize string = 'Standard_D2s_v3'
param numberOfVms int = 3
param vnetName string = 'avdVNet'
param subnetName string = 'default'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource avdHostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = {
  name: 'avdHostPool'
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    maxSessionLimit: 10
    preferredAppGroupType: 'Desktop'
  }
}

resource avdAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-07-12' = {
  name: 'avdAppGroup'
  location: location
  properties: {
    hostPoolArmPath: avdHostPool.id
    applicationGroupType: 'Desktop'
    preferredAppGroupType: 'Desktop'
  }
}

resource avdVms 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(0, numberOfVms): {
  name: 'avdVm${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'avdVm${i}'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-21h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicResources[i].id
        }
      ]
    }
  }
}]

resource nicResources 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, numberOfVms): {
  name: 'nic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${i}'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]
