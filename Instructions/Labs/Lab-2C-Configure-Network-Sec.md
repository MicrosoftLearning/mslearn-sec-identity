---
lab:
    title: 'Configure Network Security Controls'
    description: 'Apply NSG rules using Application Security Groups to a workload VM, deploy Azure Firewall with an application rule collection, route spoke traffic through the firewall, configure a Private Endpoint for a storage account, and validate the configuration using Network Watcher IP flow verify.'
    level: 300
    duration: 65
    islab: true
    primarytopics:
        - Network Security Groups
        - Application Security Groups
        - Azure Firewall
        - Private Endpoints
        - Network Watcher
---

# Configure Network Security Controls

A penetration test of your AI inference workload identified a critical network security gap: the workload VM serving the model endpoint has no NSG applied, making it directly reachable from the internet on any port. Outbound traffic from the workload subnet routes directly to the internet with no inspection or filtering. The backend storage account used by the inference service is also publicly accessible — any actor with a valid SAS token can reach it from anywhere.

Your task is to close all three gaps. You will apply NSG rules using Application Security Groups to restrict inbound traffic to the workload VM, deploy an Azure Firewall in the hub network and route all spoke outbound traffic through it, and configure a Private Endpoint for the storage account so it is no longer reachable via its public URL.

In this lab, you will:

- Start Azure Firewall deployment early (provisioning takes 10–15 minutes)
- Create an Application Security Group and NSG rules to restrict workload VM traffic
- Configure a Private Endpoint for the workload storage account
- Complete Azure Firewall configuration with an application rule collection and route table
- Validate network security controls using Network Watcher IP flow verify

This exercise should take approximately **65** minutes to complete.

---

## Start Azure Firewall deployment

> **Note**: Azure Firewall takes **10–15 minutes** to provision. This lab begins with the firewall deployment so that provisioning completes in the background while you work on NSG and Private Endpoint tasks. Do not wait for the firewall to finish before proceeding to the next section.

Azure Firewall is a managed, stateful network firewall as a service that provides centralized outbound traffic inspection for all resources in your hub-spoke network. In this lab, all outbound traffic from the `sc500-lab2c-spoke-vnet` workload subnet will route through the firewall in `sc500-lab2c-hub-vnet` — ensuring that outbound destinations are controlled by explicit application rules and all traffic is logged.

1. Sign in to the [Azure portal](https://portal.azure.com) using your **Global Administrator** credentials.

1. In the search bar, search for and select **Firewalls**.

1. Select **+ Create**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Name** | sc500-lab2c-fw |
    | **Region** | East US |
    | **Availability zone** | None |
    | **Firewall tier** | Standard |
    | **Firewall management** | Use a Firewall Policy to manage this firewall |
    | **Firewall policy** | Select **Add new**; name it `sc500-fw-policy`; select **Standard** tier; select **OK** |
    | **Virtual network** | sc500-lab2c-hub-vnet |
    | **Public IP address** | Select **Add new**; name it `sc500-lab2c-fw-pip`; select **OK** |
    | **Enable Firewall Management NIC** | Uncheck this checkbox |


1. Select **Review + create**, then select **Create**.

    > **Note**: The firewall is now deploying. **Do not wait for it to finish.** Proceed immediately to the next section — the NSG and Private Endpoint tasks will take approximately the same time as the firewall deployment. You will return to complete the firewall configuration in a later section.

---

## Create Application Security Groups and NSG rules

An **Application Security Group (ASG)** tags a virtual machine with a logical workload identity that can be referenced in NSG rules — instead of using IP addresses that change when VMs are redeployed. An **NSG** attached to the workload subnet then enforces traffic rules that reference the ASG by name, making rules resilient to infrastructure changes.

The workload VM (`sc500-lab2c-vm`) currently has no NSG applied. Any source can reach it on any port. You will create an ASG for the AI inference service, create an NSG with rules that deny inbound RDP from the internet and allow inbound HTTPS from within the virtual network, and apply the NSG to the workload subnet.

### Create the Application Security Group

1. In the Azure portal search bar, search for and select **Application security groups**.

1. Select **+ Create**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Name** | sc500-asg-ai-inference |
    | **Region** | East US |

1. Select **Review + create**, then select **Create**.

### Associate the VM with the ASG

1. In the Azure portal search bar, search for and select **Virtual machines**.

1. Select **sc500-lab2c-vm**.

1. In the left menu, under **Networking**, select **Application security groups**.

1. Select **+ Add application security groups**.

1. Select **sc500-asg-ai-inference**, then select **Add**.

### Create the NSG

1. In the Azure portal search bar, search for and select **Network security groups**.

1. Select **+ Create**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Name** | sc500-lab2c-nsg |
    | **Region** | East US |

1. Select **Review + create**, then select **Create**.

1. Select **Go to resource** to open the new NSG.

### Add inbound security rules

1. In the left menu for `sc500-lab2c-nsg`, under **Settings**, select **Inbound security rules**.

1. Select **+ Add**.

1. Configure the first rule to deny inbound RDP from the internet:

    | Setting | Value |
    |---------|-------|
    | **Source** | Any |
    | **Source port ranges** | * |
    | **Destination** | Application security group, select sc500-asg-ai-inference |
    | **Service** | RDP |
    | **Action** | Deny |
    | **Priority** | 100 |
    | **Name** | DenyInboundRDP |

1. Select **Add**.

1. Select **+ Add** again.

1. Configure the second rule to allow inbound HTTPS from the virtual network:

    | Setting | Value |
    |---------|-------|
    | **Source** | Service Tag, select VirtualNetwork |
    | **Source port ranges** | * |
    | **Destination** | Application security group, select sc500-asg-ai-inference |
    | **Service** | HTTPS |
    | **Action** | Allow |
    | **Priority** | 200 |
    | **Name** | AllowInboundHTTPS |

1. Select **Add**.

### Apply the NSG to the workload subnet

1. In the left menu for `sc500-lab2c-nsg`, under **Settings**, select **Subnets**.

1. Select **+ Associate**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Virtual network** | sc500-lab2c-spoke-vnet |
    | **Subnet** | workload-subnet |

1. Select **OK**.

    > **Note**: Associating the NSG with the **subnet** (rather than the individual NIC) ensures that all VMs deployed in `workload-subnet` inherit the same security rules. Rules referencing the ASG apply only to VMs that have been associated with `sc500-asg-ai-inference` — all other VMs in the subnet are subject to the default rules only.

---

## Configure a Private Endpoint for storage

The workload storage account (`sc500lab2cstorage`) is currently accessible via its public endpoint from any network. You will create a Private Endpoint that places a private IP for the storage account directly in `workload-subnet`, then disable public access so the account is only reachable from inside the VNet.

1. In the Azure portal search bar, search for and select **Storage accounts**.

1. Select **sc500lab2cstorage**.

1. In the left menu, under **Security + networking**, select **Networking**.

1. On the **Public access** tab, select **Manage** to confirm that public network access is currently enabled. Close the panel and return to the Networking page.

1. Select the **Private endpoints** tab.

1. Select **+ Create private endpoint**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Name** | sc500-storage-pe |
    | **Region** | East US |

1. Select **Next: Resource**.

1. On the **Resource** tab, confirm the following:

    | Setting | Value |
    |---------|-------|
    | **Resource type** | Microsoft.Storage/storageAccounts |
    | **Resource** | sc500lab2cstorage |
    | **Target sub-resource** | blob |

1. Select **Next: Virtual Network**.

1. On the **Virtual Network** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Virtual network** | sc500-lab2c-spoke-vnet |
    | **Subnet** | workload-subnet |

1. Select **Next: DNS**.

1. On the **DNS** tab, confirm **Integrate with private DNS zone** is set to **Yes** and the DNS zone shown is **privatelink.blob.core.windows.net**.

    > **Note**: The `privatelink.blob.core.windows.net` private DNS zone was pre-provisioned and linked to `sc500-lab2c-spoke-vnet`. When the private endpoint is created, an A record is automatically registered in this zone, mapping the storage account's blob service FQDN to its new private IP address.

1. Select **Review + create**, then select **Create**.

    Wait for the private endpoint to deploy (typically 1–2 minutes).

1. Return to the **Networking** settings for `sc500lab2cstorage`.

1. On the **Public access** tab, select **Manage**.

1. Set **Public network access** to **Disabled**, then select **Save**.

    > **Note**: With public access disabled, the storage account is now reachable only from resources in `sc500-lab2c-spoke-vnet` via the private endpoint. The inference service VM (`sc500-lab2c-vm`) uses the private IP for all storage operations — the public internet has no path to the data.

---

## Complete Azure Firewall configuration

By now, the Azure Firewall deployment should be complete or nearly complete. If it is still deploying, wait for it to reach the **Succeeded** state before continuing.

You will add an application rule collection that allows the workload VMs to reach Microsoft and Azure service endpoints, then create a route table that forces all outbound traffic from the spoke subnet through the firewall.

### Verify firewall deployment

1. In the Azure portal search bar, search for and select **Firewalls**.

1. Select **sc500-lab2c-fw**.

1. On the **Overview** page, confirm the provisioning state shows **Succeeded** and note the **Private IP address** of the firewall. You will need this IP address when creating the route table.

    > **Note**: Copy the firewall's private IP address to a text file. It will look like `10.3.1.x` — an address from the `AzureFirewallSubnet` range.

### Add an application rule collection

1. On the **Overview** page for `sc500-lab2c-fw`, locate the **Firewall policy** field and select **sc500-fw-policy** to open the policy.

1. In the left menu for `sc500-fw-policy`, under **Rules**, select **Application rules**.

1. Select **+ Add a rule collection**.

1. Configure the rule collection:

    | Setting | Value |
    |---------|-------|
    | **Name** | sc500-allow-outbound |
    | **Rule collection type** | Application |
    | **Priority** | 100 |
    | **Rule collection action** | Allow |

1. Under **Rules**, add the following rule:

    | Setting | Value |
    |---------|-------|
    | **Name** | AllowMicrosoftEndpoints |
    | **Source type** | IP Address |
    | **Source** | 10.4.0.0/16 |
    | **Protocol** | https:443 |
    | **Destination type** | FQDN |
    | **Destination** | *.microsoft.com,*.azure.com,*.windows.net |

1. Select **Add**.

    > **Note**: This rule allows outbound HTTPS traffic from the entire spoke VNet address space to Microsoft-owned FQDN patterns. In a production environment, you would narrow this to specific endpoints required by your workload (for example, specific Azure Cognitive Services or Foundry endpoints) rather than allowing all `*.azure.com` destinations.

### Create a route table to force traffic through the firewall

1. In the Azure portal search bar, search for and select **Route tables**.

1. Select **+ Create**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Name** | sc500-spoke-rt |
    | **Propagate gateway routes** | No |
    | **Region** | East US |

1. Select **Review + create**, then select **Create**.

1. Select **Go to resource** to open the route table.

1. In the left menu, under **Settings**, select **Routes**.

1. Select **+ Add**.

1. Configure the default route:

    | Setting | Value |
    |---------|-------|
    | **Route name** | DefaultToFirewall |
    | **Destination type** | IP Addresses |
    | **Destination IP addresses/CIDR ranges** | 0.0.0.0/0 |
    | **Next hop type** | Virtual appliance |
    | **Next hop address** | The firewall's private IP address (noted earlier) |

1. Select **Add**.

1. In the left menu, select **Subnets**.

1. Select **+ Associate**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Virtual network** | sc500-lab2c-spoke-vnet |
    | **Subnet** | workload-subnet |

1. Select **OK**.

    > **Note**: With this route table in place, all outbound traffic from `workload-subnet` — including any traffic destined for the public internet — is forced through `sc500-lab2c-fw` before leaving the spoke network. Only traffic that matches the firewall's application rules is permitted to exit. All other destinations are implicitly denied by the firewall's default deny posture.

---

## Validate network security controls with Network Watcher

Network Watcher's **IP flow verify** tool tests whether a specific traffic flow would be allowed or denied by the effective NSG rules applied to a VM's network interface. You will use it to confirm that inbound RDP is blocked by the NSG you created, and that inbound HTTPS is allowed.

1. In the Azure portal search bar, search for and select **Network Watcher**.

1. In the left menu, under **Network diagnostic tools**, select **IP flow verify**.

1. Configure the following to test inbound RDP:

    | Setting | Value |
    |---------|-------|
    | **Virtual machine** | sc500-lab2c-vm |
    | **Network interface** | Select the NIC for sc500-lab2c-vm |
    | **Protocol** | TCP |
    | **Direction** | Inbound |
    | **Local IP address** | Leave as the auto-detected private IP of the VM |
    | **Local port** | 3389 |
    | **Remote IP address** | 8.8.8.8 (a public internet IP) |
    | **Remote port** | 60000 |

1. Select **Verify IP flow**.

    Confirm the result shows **Access denied** and identifies `DenyInboundRDP` as the rule responsible.

1. Change **Local port** to `443` and select **Verify IP flow** again.

    Confirm the result shows **Access allowed** and identifies `AllowInboundHTTPS` as the rule responsible.

    > **Note**: IP flow verify evaluates the effective security rules — the combined result of all NSGs applied at the NIC level and the subnet level. It does not test actual traffic; it simulates the NSG evaluation logic. This makes it a fast, non-destructive way to validate that a firewall rule is configured correctly before testing with real traffic.

1. In the left menu for **Network Watcher**, select **Effective security rules** (under **Network diagnostic tools**).

1. Select **sc500-lab2c-vm** and its network interface. The subscription, resource group, VM, and NIC fields are populated automatically.

1. Under the **"Click on a rule row to see the expanded list of prefixes"** section, select **sc500-lab2c-nsg** to expand the inbound and outbound rule lists.

1. In the **Inbound** rules list, confirm the following rules appear:

    | Priority | Name | Action |
    |----------|------|--------|
    | 100 | DenyInboundRDP | Deny |
    | 200 | AllowInboundHTTPS | Allow |

    The Azure default rules (`AllowVnetInBound` at 65000, `AllowAzureLoadBalancerInBound` at 65001, `DenyAllInBound` at 65500) appear below your custom rules. This confirms your rules are evaluated first — any traffic matching priority 100 or 200 never reaches the defaults.

---

## Summary

In this lab, you applied three layers of network security controls to an AI workload environment that had no network restrictions in place.

You created an **Application Security Group** to tag the workload VM with a logical identity, and created an **NSG** with rules that deny inbound RDP from the internet and allow inbound HTTPS from within the virtual network. Attaching the NSG to the subnet ensures all current and future VMs in `workload-subnet` inherit these rules. You used **Network Watcher IP flow verify** to confirm that the rules produce the expected allow/deny outcomes without generating actual traffic.

You deployed **Azure Firewall** in the hub network and configured an application rule collection that permits the workload subnet to reach Microsoft and Azure service endpoints over HTTPS. A route table with a default route pointing to the firewall private IP forces all outbound spoke traffic through the firewall — outbound destinations not explicitly permitted by the application rules are denied.

You configured a **Private Endpoint** for the workload storage account in `workload-subnet` and disabled public access, so the storage account is now reachable only from resources inside the VNet via its private IP. The pre-provisioned private DNS zone ensures that clients in the spoke VNet resolve the storage account FQDN to the private endpoint address rather than the public endpoint.
