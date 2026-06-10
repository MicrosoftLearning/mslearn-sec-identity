---
lab:
    title: 'Secure Container Workloads with AKS and Defender for Containers'
    description: 'Enable Defender for Containers on a pre-provisioned AKS cluster, review security recommendations, enable registry image scanning, and remediate access and network security gaps in Azure Container Registry.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Defender for Containers
        - Azure Kubernetes Service (AKS)
        - Azure Container Registry (ACR)
---

# Secure Container Workloads with AKS and Defender for Containers

Your organization is running AI inference microservices in AKS. A security review identified three high-risk gaps:

- Runtime threat detection is not enabled for the cluster.
- The container registry is not being scanned for known vulnerabilities.
- Registry access is overly permissive and not restricted by network boundaries.

In this lab, you will remediate these gaps by enabling Defender for Containers, reviewing recommendations, enabling vulnerability scanning in ACR, and tightening identity and network controls.

In this lab, you will:

- Enable Defender for Containers on the subscription.
- Verify AKS monitoring coverage in Defender for Cloud.
- Review and record AKS security recommendations.
- Enable image vulnerability scanning for ACR.
- Review CVE findings for a pre-seeded image.
- Disable ACR admin user and assign scoped RBAC roles.
- Restrict ACR network access to approved public network ranges.

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab uses pre-provisioned resources in the subscription, including `sc500-lab4b-aks` and `sc500lab4bacr`.

---

## Review the Preconfigured State

> **Instructor setup required for each new lab environment**: After deploying the Lab 4B infrastructure template, run the following Azure CLI command once to seed the required image in ACR:
>
> `az acr import --name sc500lab4bacr --source docker.io/library/nginx:1.19.0-alpine --image nginx:1.19.0-alpine --force`
>
> Optional verification command:
>
> `az acr repository show-tags --name sc500lab4bacr --repository nginx --output table`

1. In the Azure portal, open **Resource groups** and select **sc500-lab4b-rg**.

1. Confirm the following resources are present:

    - **sc500-lab4b-aks**
    - **sc500lab4bacr**
    - **sc500-lab4b-vnet**

1. Open **sc500lab4bacr** and confirm the `nginx:1.19.0-alpine` image exists in the registry.

---

## Enable Defender for Containers

1. Sign in to the [Azure portal](https://portal.azure.com) with your Global Administrator account.

1. In the search bar, select **Microsoft Defender for Cloud**.

1. Select **Environment settings**.

1. Select the active lab subscription.

1. On the **Defender plans** page, turn **Containers** to **On**.

1. Select **Save**.

1. Return to **Defender for Cloud** and confirm the Containers plan shows as enabled for the subscription.

---

## Verify AKS Coverage and Recommendations

1. In Defender for Cloud, go to **Inventory** or **Assets** and locate **sc500-lab4b-aks**.

1. Select **sc500-lab4b-aks** from the list to open the cluster resource. Confirm that Defender for Containers coverage is active.

1. Go to **Recommendations**.

1. Filter by resource name **sc500-lab4b-aks**.

1. Review the recommendations.

1. Select one **recommendation** and review the remediation guidance for each recommendation.

---

## Enable ACR Vulnerability Scanning and Validate Findings

1. In the Azure portal, open **Microsoft Defender for Cloud**.

1. Select **Environment settings**, and then select your lab subscription.

1. Select **Defender plans** (or **Defender plans coverage**), and then select **Settings** for the **Containers** plan.

1. Turn on **Registry access** and ensure **Security findings** is enabled.

1. Select **Continue** to return to the Defender plans page, and then select **Save**.

1. Return to the Azure portal home, open **Container registries**, and then select **sc500lab4bacr**.

1. Open **Services** > **Repositories**, select **nginx**, and then select the **1.19.0-alpine** tag.

1. Review available vulnerability evidence for this registry image, if available.

1. Close **Container registries** and open **Microsoft Defender for Cloud**.

1. Go to recommendations and filter for **sc500lab4bacr**.

---

## Apply ACR Access Controls

1. In **sc500lab4bacr**, open **Settings** > **Access keys**.

1. Set **Admin user** to **Disabled** by **unchecking** the checkbox.

1. Open **Access control (IAM)** for **sc500lab4bacr**.

1. Select **+ Add** > **Add role assignment**.

1. On the **Role** tab, select **AcrPull**, and then select **Next**.

1. On the **Members** tab, select **User, group, or service principal**, select **+ Select members**, choose **sc500-user08**, and then select **Review + assign**.

1. Repeat the role assignment process: select **+ Add** > **Add role assignment**, choose **AcrPush**, and select **Next**.

1. On the **Members** tab, select **User, group, or service principal**, select **+ Select members**, choose **sc500-user09**, and then select **Review + assign**.

1. Verify both assignments are visible in role assignments.

---

## Restrict ACR Network Access

1. In **sc500lab4bacr**, open **Settings** > **Networking**.

1. On the **Public access** tab, in **Public network access**, select **Selected networks**.

1. Under **Firewall**, select **Add your client IP address** so your current session stays connected.

1. Select **Save**.

1. Confirm that **Selected networks** remains selected after save.

1. Verify that only the configured firewall IP entries are listed under **Firewall**.

1. Confirm that access from non-approved public networks is denied by design when **Selected networks** is enabled.

> [!NOTE]
> The current Azure portal experience for ACR uses firewall IP rules on **Public access** when you select **Selected networks**. Virtual network and subnet selection is configured through **Private access** by creating a private endpoint connection, which isn't required for this lab.

---

## Summary

In this lab, you enabled Defender for Containers for AKS runtime visibility, reviewed cluster recommendations, enabled ACR image vulnerability scanning, and remediated identity and network exposure in the registry.

You now have a layered security posture for container workloads:

- Runtime and configuration visibility in Defender for Containers.
- Image vulnerability visibility before deployment.
- Least-privilege registry access with RBAC.
- Reduced external exposure through network restrictions.
