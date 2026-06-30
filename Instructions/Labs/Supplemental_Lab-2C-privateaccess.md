---
lab:
    title: 'Configure Microsoft Entra Private Access (Add-On Lab)'
    description: 'Configure Microsoft Entra Private Access to provide secure, identity-governed access to a private workload resource without requiring a VPN — using the pre-provisioned Global Secure Access connector as the bridge between the Entra identity plane and the private network.'
    level: 300
    duration: 30
    islab: true
    primarytopics:
        - Microsoft Entra Private Access
        - Global Secure Access
        - Zero Trust Network Access
---

# Configure Microsoft Entra Private Access (Add-On Lab)

> **Note**: This is an add-on lab for Lab 2C. It requires the hub-spoke network and workload VM (`sc500-lab2c-vm`) from Lab 2C to be in place — keep the Lab 2C environment as-is before starting. You will create and register the Global Secure Access connector as part of this lab. Before starting, open the [Microsoft Entra admin center](https://entra.microsoft.com), expand **Global Secure Access** in the left menu, and confirm the section is accessible — this verifies Global Secure Access is licensed and enabled on your tenant.

A developer working remotely needs to reach the AI inference service endpoint running on `sc500-lab2c-vm` — but the VM is now in a private subnet behind Azure Firewall with no public inbound access. Traditional solutions (VPN, jump host, public IP) either expand the attack surface or require infrastructure the team does not have. 

**Microsoft Entra Private Access** provides zero-trust network access (ZTNA) to private resources without requiring a VPN. It uses a lightweight connector installed in the private network to relay traffic from authenticated Entra ID users — so access is governed by identity, Conditional Access policies, and session controls rather than network perimeter membership.

In this lab, you will:

- Create a dedicated connector subnet in the spoke virtual network
- Deploy the Global Secure Access connector VM and install the connector agent
- Verify the connector is registered and active
- Configure a Quick Access private resource targeting the workload VM's private IP
- Assign the Quick Access application to a user
- Review the Global Secure Access configuration and logs

This exercise should take approximately **30** minutes to complete.

---

## Create the connector subnet

The Global Secure Access connector must run on a VM inside your private network so it can reach the resources you want to protect. You will create a dedicated subnet in the spoke virtual network — separate from `workload-subnet` — so the connector VM is not subject to the same NSG and route table rules applied to the workload.

1. In the [Azure portal](https://portal.azure.com), search for and select **Virtual networks**.

1. Select **sc500-lab2c-spoke-vnet**.

1. In the left menu, under **Settings**, select **Subnets**.

1. Select **+ Subnet**.

1. Configure the subnet:

    | Setting | Value |
    |---------|-------|
    | **Subnet purpose** | Default |
    | **Name** | connector-subnet |
    | **Starting address** | 10.4.1.0 |
    | **Size** | /24 (256 addresses) |
    | **Network security group** | None |
    | **Route table** | None |
    | **Enable private subnet** | Unchecked |
    | **NAT gateway** | None |
    | **Service endpoints** | None |
    | **Subnet delegation** | None |
    | **Network policy for private endpoints** | Disabled |

1. Select **Add**.

    > **Note**: The connector-subnet intentionally has no route table. The `workload-subnet` uses a route table that forces all outbound traffic through Azure Firewall — which would require additional firewall application rules for the GSA connector registration endpoints. By using a separate subnet with default Azure routing, the connector VM has direct outbound HTTPS access to Microsoft's Global Secure Access infrastructure, which is the outbound-only pattern the connector requires.

---

## Deploy the connector VM

1. In the Azure portal, search for and select **Virtual machines**.

1. Select **+ Create** → **Azure virtual machine**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2c-rg |
    | **Virtual machine name** | sc500-lab2c-gsa-connector-vm |
    | **Region** | East US |
    | **Image** | Windows Server 2022 Datacenter: Azure Edition |
    | **Size** | Standard_B2s |
    | **Administrator username** | sc500vmadmin |
    | **Administrator password** | SC500-Lab2C-2026! |
    | **Public inbound ports** | Allow selected ports |
    | **Select inbound ports** | RDP (3389) |

1. Select **Next: Disks**, accept defaults, then select **Next: Networking**.

1. On the **Networking** tab, configure:

    | Setting | Value |
    |---------|-------|
    | **Virtual network** | sc500-lab2c-spoke-vnet |
    | **Subnet** | connector-subnet (10.4.1.0/24) |
    | **Public IP** | (new) — accept the default name |
    | **NIC network security group** | Basic |
    | **Public inbound ports** | Allow selected ports — RDP (3389) |

1. Accept remaining defaults and select **Review + create**, then **Create**.

    > **Note**: The public IP and RDP access are needed only to connect to the VM and install the connector agent. After the connector registers, it establishes an outbound-only tunnel to Microsoft's GSA infrastructure — no inbound access is required for ongoing operation. In a production environment you would use Azure Bastion or an existing jump host instead of a public IP.

1. Wait for the deployment to complete before proceeding.

---

## Install and register the connector agent

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), expand **Global Secure Access** and select **Connect**.

1. Select **Connectors and sensors**.

1. Select **Download connector service**.

1. On the terms page, review the terms and select **Accept terms and download**.

    This downloads the **MicrosoftEntraPrivateNetworkConnectorInstaller.exe** installer file.

1. In the Azure portal, navigate to **Virtual machines** → **sc500-lab2c-gsa-connector-vm** → **Overview** and note the **Public IP address**.

1. Open **Remote Desktop Connection** and connect to the public IP address using:
    - **Username**: sc500vmadmin
    - **Password**: SC500-Lab2C-2026!

1. Inside the RDP session, open **Server Manager** (it launches automatically on login, or search for it in the Start menu).

1. In the left pane, select **Local Server**.

1. Locate **IE Enhanced Security Configuration** — it shows as **On**. Select **On** next to it.

1. In the dialog, set both **Administrators** and **Users** to **Off**, then select **OK**.

    > **Note**: IE Enhanced Security Configuration is enabled by default on Windows Server and blocks the browser-based sign-in popup that the connector installer launches. Turning it off allows the authentication flow to complete. This setting only affects this VM.

1. Copy and run the connector installer.

1. When prompted, sign in with your **Global Administrator** credentials to register the connector to your tenant.

    The installer registers the connector and starts the **Microsoft Entra Private Network Connector** Windows service automatically.

1. Close the RDP session.

---

## Verify the connector is active

1. In the Entra admin center, navigate to **Global Secure Access** → **Connect** → **Connectors and sensors**.

    Confirm that **sc500-lab2c-gsa-connector-vm** appears in the list with a status of **Active**.

    > **Note**: Allow up to 5 minutes after the agent installs for the status to update to Active. If it remains Inactive, sign back in to the VM and confirm the **Microsoft Entra Private Network Connector** Windows service is in the **Running** state.

1. Note the **Connector group** the **sc500-lab2c-gsa-connector-vm** belongs to — you will reference this when configuring Quick Access in the next task.

---

## Configure Quick Access for the workload VM

**Quick Access** is the fastest way to configure Entra Private Access for a single private resource or range. It creates an Enterprise Application in Entra ID that represents the private resource, and maps traffic to a specific IP address and port range through the registered connector.

You will configure Quick Access to provide access to the workload VM (`sc500-lab2c-vm`) on TCP port 443 — the HTTPS port used by the inference service.

1. In the Entra admin center, under **Global Secure Access**, select **Applications**.

1. Select **Quick access**.

1. On the **Quick access** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Name** | sc500-inference-access |
    | **Connector group** | Default (or the group containing the sc500-lab2c-gsa-connector) |

1. Under **Quick access application segments**, select **+ Add Quick access application segment**.

1. Configure the segment:

    | Setting | Value |
    |---------|-------|
    | **Destination type** | IP address |
    | **IP address** | The private IP address of sc500-lab2c-vm (find it in Virtual machines → sc500-lab2c-vm → Overview → Private IP address) |
    | **Ports** | 443 |
    | **Protocol** | TCP |

1. Select **Apply**, then select **Save**.

    > **Note**: Quick Access creates an Enterprise Application in Entra ID named `sc500-inference-access`. This application appears in **Entra ID → Enterprise applications** and can be targeted by Conditional Access policies — allowing you to enforce MFA, device compliance, or sign-in risk controls on all access to the private resource, without any network-level change.

---

## Assign the Quick Access application to a user

Like any Enterprise Application, the Quick Access application must be assigned to the users or groups who need access. Without an assignment, no user can reach the private resource through Global Secure Access.

1. In the Entra admin center, navigate to **Identity** → **Applications** → **Enterprise applications**.

1. Search for and select **sc500-inference-access**.

1. In the left menu, under **Manage**, select **Users and groups**.

1. Select **+ Add user/group**.

1. Under **Users**, select **None selected**.

1. Search for and select **sc500-user07**, then select **Select**.

1. Under **Select a role**, the role is pre-set to **User** — this is correct.

1. Select **Assign**.

    > **Note**: `sc500-user07` now has an assignment to the `sc500-inference-access` Quick Access application. When this user is signed into a device running the **Global Secure Access client**, traffic destined for the workload VM's private IP on port 443 is automatically tunneled through the connector — without any VPN configuration or network firewall rule change.

---

## Review the Quick Access configuration

1. Return to **Global Secure Access** → **Applications** → **Quick access**.

1. Confirm the `sc500-inference-access` application shows the configured segment:
    - Destination: workload VM private IP
    - Port: 443
    - Protocol: TCP

1. In the Entra admin center, navigate to **Global Secure Access** → **Monitor** → **Traffic logs**.

    > **Note**: In a production scenario, you would install the **Global Secure Access client** on an end-user device and sign in as `sc500-user07` to generate traffic through the connector. Traffic logs capture all tunneled sessions — showing which user accessed which private resource, when, and from which device. This log is the identity-governed audit trail that replaces the network perimeter log in a zero-trust architecture.

    > **Lab constraint**: Installing and testing the Global Secure Access client on the lab VM is outside the scope of this add-on lab. The configuration you completed — connector registration, Quick Access application segment, and user assignment — is the complete administrative provisioning workflow. In a production deployment, end users install the lightweight client from `aka.ms/GlobalSecureAccessClient` and private access begins working transparently at sign-in.

---

## Summary

In this add-on lab, you configured **Microsoft Entra Private Access** to provide identity-governed access to the AI inference workload VM without exposing it to the public internet or requiring a VPN.

The **Global Secure Access connector** installed on `sc500-lab2c-gsa-connector-vm` acts as the bridge between the Entra identity plane and the private network. You created a **Quick Access application segment** targeting the workload VM's private IP on port 443, making the resource available to authorized users through the connector tunnel.

By assigning the Enterprise Application to `sc500-user07`, you established that access is governed by Entra ID identity — not network membership. The same user could be targeted by **Conditional Access policies** applied to this application, requiring MFA, compliant device status, or sign-in risk thresholds before private access is granted. This is the zero-trust network access model: identity and device health replace the VPN tunnel as the access control boundary.
