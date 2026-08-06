---
lab:
    title: 'Secure Container Workloads with AKS and Defender for Containers'
    description: 'Enable Defender for Containers on a pre-provisioned AKS cluster, verify container and registry monitoring, and remediate access and network security gaps in Azure Container Registry.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Defender for Containers
        - Azure Kubernetes Service (AKS)
        - Azure Container Registry (ACR)
---

# Lab Setup

Complete these steps before starting the exercise to deploy the resources and seed the container image used in the lab:

1. Open the **Azure portal** at `https://portal.azure.com` and sign in with **User1**.

1. In the portal top bar, select the **Cloud Shell** icon (**>_**). If prompted, select **Bash** and **No storage account required**.

1. Register the Microsoft.Security resource provider required for Defender plans, and wait for registration to finish:

    ```bash
    az provider register --namespace Microsoft.Security --wait
    az provider show --namespace Microsoft.Security --query registrationState -o tsv
    ```

    Confirm the output is `Registered` before continuing.

1. Using the credentials provided for **User2** and **User3**, copy the exact username for each account. Keep both usernames available for the role-assignment steps.

1. In Cloud Shell, replace `<User2-UPN>` and `<User3-UPN>` with the exact usernames, and then resolve both directory object IDs:

    ```bash
    USER2_UPN='<User2-UPN>'
    USER3_UPN='<User3-UPN>'

    USER2_OBJECT_ID=$(az ad user show --id "$USER2_UPN" --query id -o tsv)
    USER3_OBJECT_ID=$(az ad user show --id "$USER3_UPN" --query id -o tsv)

    test -n "$USER2_OBJECT_ID" || { echo "User2 could not be resolved in Microsoft Entra ID."; exit 1; }
    test -n "$USER3_OBJECT_ID" || { echo "User3 could not be resolved in Microsoft Entra ID."; exit 1; }

    echo "User2 object ID: $USER2_OBJECT_ID"
    echo "User3 object ID: $USER3_OBJECT_ID"
    ```

1. Copy both object IDs. Keep them available in case the portal member picker doesn't return either account.

1. Generate a stable eight-character suffix from the lab subscription ID:

    ```bash
    LAB_INSTANCE_ID=$(az account show --query id -o tsv | tr -d '-' | cut -c1-8)
    echo $LAB_INSTANCE_ID
    ```

1. Copy the displayed value, and then close Cloud Shell. You will use it as the **Lab Instance Id** during template deployment.

1. In the portal search bar, find and open **Deploy a custom template**.

1. Select **Build your own template in the editor**, and then select **Load file**.

1. Select **lab-4b-setup.json** from the **F:\AllFiles\Lab-4B** folder on the lab VM, and then select **Save**.

1. On the **Basics** page, paste the suffix you copied into **Lab Instance Id**.

1. Select **Review + create**, and then select **Create**.

    > **Note**: The AKS deployment normally takes 5-10 minutes. Wait until the deployment shows **Succeeded** before continuing.

1. Open Cloud Shell again and run the following commands to identify the generated registry name, import the required image, and verify the tag:

    ```bash
    ACR_NAME=$(az acr list --resource-group sc500-lab4b-rg --query "[0].name" -o tsv)
    echo $ACR_NAME
    test -n "$ACR_NAME" || { echo "No container registry was found in sc500-lab4b-rg."; exit 1; }
    az acr import --name $ACR_NAME --source docker.io/library/nginx:1.19.0-alpine --image nginx:1.19.0-alpine --force
    az acr repository show-tags --name $ACR_NAME --repository nginx --output table
    ```

1. Confirm the output includes `1.19.0-alpine`, copy the displayed registry name, and then close Cloud Shell.

===

# Secure Container Workloads with AKS and Defender for Containers

Your organization is running AI inference microservices in AKS. A security review identified three high-risk gaps:

- Runtime threat detection is not enabled for the cluster.
- The container registry is not being scanned for known vulnerabilities.
- Registry access is overly permissive and not restricted by network boundaries.

In this lab, you will remediate these gaps by enabling Defender for Containers, verifying deterministic monitoring settings, preparing an ACR image for scanning, and tightening identity and network controls.

In this lab, you will:

- Enable Defender for Containers on the subscription.
- Verify container and registry monitoring settings in Defender for Cloud.
- Import an ACR image and verify it is available for vulnerability scanning.
- Disable ACR admin user and assign scoped RBAC roles.
- Restrict ACR network access to approved public network ranges.

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab uses the pre-provisioned AKS cluster `sc500-lab4b-aks`, virtual network `sc500-lab4b-vnet`, and a container registry whose name begins with `sc500lab4bacr`. Throughout the lab, `<acr-name>` refers to that generated registry name.

---

## Review the Preconfigured State

1. In the Azure portal, open **Resource groups**, and then select **sc500-lab4b-rg**.

1. Confirm the resource group contains:

    - **sc500-lab4b-aks**
    - **sc500-lab4b-vnet**
    - One container registry whose name begins with **sc500lab4bacr**

1. Open **<acr-name>**, select **Services** > **Repositories**, and then select **nginx**.

1. Confirm the **1.19.0-alpine** tag is present.

---

## Enable Defender for Containers

1. In the Azure portal, open **Microsoft Defender for Cloud**.

1. Expand **Management**, select **Environment settings**, and then select **Expand all**.

1. Select the active lab subscription.

1. On **Settings | Defender plans**, set **Containers** to **On**, and then select **Save**.

1. Confirm the success notification appears and the **Containers** row shows **Full** under **Monitoring coverage**.

---

## Verify Container and Registry Monitoring

1. On the **Containers** row, confirm the resource quantity includes one container registry and the Kubernetes cores from **sc500-lab4b-aks**.

1. Select **Settings >** for the **Containers** plan.

1. On **Settings & monitoring**, confirm **Registry access** is **On** and its configuration shows **Security findings: On**.

1. Select **Continue** to return to the Defender plans page, and then select **Save** if the button is enabled.

1. Return to **<acr-name>**, select **Services** > **Repositories** > **nginx**, and then select the **1.19.0-alpine** tag.

1. Confirm the image metadata opens successfully.

> [!NOTE]
> Defender recommendations and image vulnerability findings are generated asynchronously and can take up to 24 hours to appear in a new subscription. They are not required to complete this lab. If findings are available, you can optionally review them under **Microsoft Defender for Cloud** > **Recommendations** by filtering for **sc500-lab4b-aks** or **<acr-name>**.

---

## Apply ACR Access Controls

1. In **<acr-name>**, open **Settings** > **Access keys**.

1. Set **Admin user** to **Disabled** by **unchecking** the checkbox.

1. Open **Access control (IAM)** for **<acr-name>**.

1. Select **+ Add** > **Add role assignment**.

1. On the **Role** tab, select **AcrPull**, and then select **Next**.

1. On the **Members** tab, select **User, group, or service principal**, and then select **+ Select members**.

1. Paste the exact **User2** username copied earlier. If the matching account appears, select it, and then select **Review + assign**.

1. Repeat the role assignment process: select **+ Add** > **Add role assignment**, choose **AcrPush**, and select **Next**.

1. On the **Members** tab, select **User, group, or service principal**, and then select **+ Select members**.

1. Paste the exact **User3** username copied earlier. If the matching account appears, select it, and then select **Review + assign**.

1. If either member picker doesn't return the matching account, open Cloud Shell and run the following fallback. Replace `<acr-name>`, `<User2-object-id>`, and `<User3-object-id>` with the values you copied earlier. The commands create only assignments that are missing:

    ```bash
    ACR_NAME='<acr-name>'
    USER2_OBJECT_ID='<User2-object-id>'
    USER3_OBJECT_ID='<User3-object-id>'
    ACR_ID=$(az acr show --name "$ACR_NAME" --query id -o tsv)
    test -n "$ACR_ID" || { echo "The container registry could not be resolved."; exit 1; }

    USER2_ASSIGNMENT_COUNT=$(az role assignment list \
      --scope "$ACR_ID" \
      --query "[?principalId=='$USER2_OBJECT_ID' && roleDefinitionName=='AcrPull'] | length(@)" \
      -o tsv)

    if [ "$USER2_ASSIGNMENT_COUNT" = "0" ]; then
      az role assignment create \
        --assignee-object-id "$USER2_OBJECT_ID" \
        --assignee-principal-type User \
        --role AcrPull \
        --scope "$ACR_ID"
    fi

    USER3_ASSIGNMENT_COUNT=$(az role assignment list \
      --scope "$ACR_ID" \
      --query "[?principalId=='$USER3_OBJECT_ID' && roleDefinitionName=='AcrPush'] | length(@)" \
      -o tsv)

    if [ "$USER3_ASSIGNMENT_COUNT" = "0" ]; then
      az role assignment create \
        --assignee-object-id "$USER3_OBJECT_ID" \
        --assignee-principal-type User \
        --role AcrPush \
        --scope "$ACR_ID"
    fi

    az role assignment list \
      --scope "$ACR_ID" \
      --query "[?roleDefinitionName=='AcrPull' || roleDefinitionName=='AcrPush'].{Role:roleDefinitionName,Principal:principalName}" \
      -o table
    ```

1. Return to **Access control (IAM)** > **Role assignments**, select **Refresh**, and verify both assignments:

    - **AcrPull** for the exact User2 account.
    - **AcrPush** for the exact User3 account.

---

## Restrict ACR Network Access

1. In **<acr-name>**, open **Settings** > **Networking**.

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

In this lab, you enabled Defender for Containers, verified container and registry monitoring coverage, prepared a registry image for vulnerability scanning, and remediated identity and network exposure in the registry.

You now have a layered security posture for container workloads:

- Runtime and configuration visibility in Defender for Containers.
- Registry image monitoring configured for vulnerability visibility after Defender ingestion.
- Least-privilege registry access with RBAC.
- Reduced external exposure through network restrictions.
