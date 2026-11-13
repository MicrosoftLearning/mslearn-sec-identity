---
title: Exercise Instructions
permalink: index.html
layout: home
---

<!--
Change the title above AND IN THE _config.yml FILE (so that the page header in the GitHub Pages site automatically shows the site name).

When you're ready for the labs to be live - make the repo public and enable GitHub Pages publishing from the main branch (in the repo Settings | Pages).
-->

This page lists exercises associated with Microsoft skilling content on [Microsoft Learn](https://learn.microsoft.com)

<!-- You can edit the paragraph above to provide a more specific description and links to content on Learn.

Include the following note if an Azure subscription is required (or add something similar for any other requirements, such as a Microsoft 365 account).

> **Note**: To complete these exercises, you will need a [Microsoft Azure subscription](https://azure.microsoft.com/free) in which you have sufficient permissions to create and configure the required resources.

If a more complex setup is required, create a separate markdown file with setup instructions at \Instructions\Labs\00-setup.md - being sure to include "lab.title"" metadata at the top so it shows up the list below
-->

## Before you start: lab environment and requirements

These exercises are designed to run in the **hosted lab environment** provided with Microsoft authorized instructor-led training. That environment gives you a temporary Microsoft 365 tenant and Azure subscription with the licences, users (such as **MOD Administrator** and **Adele Vance**) and credentials the labs refer to, and it's reset at the end of each session.

If you're working through the labs on your own, use a Microsoft 365 tenant and Azure subscription that you're authorized to administer, and check that they have what each lab needs. Several labs fail partway through without the right licence.

| Lab | What your own tenant or subscription needs |
|-----|--------------------------------------------|
| Configure Privileged Identity Management | Microsoft Entra ID P2 (or Microsoft Entra ID Governance) |
| Enforce MFA with Conditional Access | Microsoft Entra ID P1 or P2. Security defaults turned off before the policy is enabled. A licence that includes Microsoft Forms (for example Microsoft 365 E5) for the test user |
| Identify AI Data Risks with Microsoft Purview | A licence that includes SharePoint Online and Microsoft Purview, for example Microsoft 365 E5. Without it, SharePoint isn't set up in the tenant and the lab's site can't be created. Microsoft 365 Copilot for the optional Copilot signals |
| Azure labs (Key Vault, Policy and RBAC, Storage, SQL Database, Network Security, AI Gateway and Foundry, AKS, App Services and API Management) | An Azure subscription where you can create resources and assign roles. These labs create billable resources, so delete them when you're done |
| Defender for Cloud labs (Monitor AI Security, Defender CSPM) | An Azure subscription with the Defender for Cloud plans named in the lab. Some plans are billed |
| Configure Microsoft Sentinel Data Collection and Automation | An Azure subscription with a Microsoft Sentinel-enabled workspace and the Security Administrator role |
| Configure and Use Microsoft Security Copilot | Security Compute Units (SCUs), which are billed, plus the Security Administrator and Global Administrator roles |

Check each lab's **Lab Setup** section for the full list of roles and setup steps.

### Azure quotas

New Azure subscriptions start with low or zero quota for some of the resources these labs deploy, so a deployment can fail with a quota error even when the template is correct. These were the gaps on a new pay-as-you-go subscription (checked November 2026):

| Lab | Resource | Default quota on a new subscription | What to do |
|-----|----------|-------------------------------------|------------|
| Configure AI Gateway and Foundry Security Controls (3C) | Azure OpenAI `gpt-5.4-mini` GlobalStandard, 10,000 TPM (`capacity: 10`) | 0 | Request quota at `https://aka.ms/oai/stuquotarequest` before you start. Requests can take time and may be declined for new subscriptions |
| Monitor AI Security with Defender for Cloud (3D) | Azure OpenAI `gpt-5.4-mini` GlobalStandard, 20,000 TPM (`capacity: 20`) | 0 | As above. Requesting 20 covers both labs |
| Secure Container Workloads with AKS (4B) | Standard DCASv5 Family vCPUs (default `agentPoolVmSize` is `Standard_DC2as_v5`) | 0 | Set `agentPoolVmSize` to a size your subscription has quota for, such as `Standard_D2s_v6`, or request DCASv5 quota |
| Explore Defender for Cloud Security Posture and CSPM (4D) | Standard DSv5 Family vCPUs (default VM size is `Standard_D2s_v5`) | 0 | Choose `Standard_D2s_v6` from the allowed sizes, or request DSv5 quota |

Other quotas these labs use (Total Regional vCPUs, Dsv6 vCPUs, public IP addresses) were high enough by default. To check your own limits, open **Quotas** in the Azure portal, or run `az vm list-usage --location eastus -o table` and `az cognitiveservices usage list --location eastus -o table`.

> **Note**: Free trial subscriptions aren't eligible for quota increases. To request more quota you need a pay-as-you-go subscription, and the labs then create billed resources.

<hr>

{% assign labs = site.pages | where_exp:"page", "page.url contains '/Instructions/Labs'" %}
{% for activity in labs  %}
{% if activity.lab.title %}
### [{{ activity.lab.title }}]({{ site.github.url }}{{ activity.url }})


{% if activity.lab.level %}**Level**: {{activity.lab.level}} \| {% endif %}{% if activity.lab.duration %}**Duration**: {{activity.lab.duration}}{% endif %}

{% if activity.lab.description %}
*{{activity.lab.description}}*
{% endif %}
<hr>
{% endif %}
{% endfor %}
