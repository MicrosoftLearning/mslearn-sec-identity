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
