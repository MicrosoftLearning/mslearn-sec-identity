# Lab 3A Setup - SharePoint Site Configuration

This folder contains the setup materials for **SC-500 Lab 3A: Identify AI Data Risks with Microsoft Purview**.

## Overview

Lab 3A requires a pre-configured SharePoint site named **sc500-ai-datastore** with:
- Oversharing configuration (shared with "Everyone except external users")
- Sample documents containing HR and financial data
- No sensitivity labels applied to documents
- Copilot interaction signals (generated through normal Copilot usage)

## Setup Options

### Option 1: PowerShell Script (Recommended)

Use the provided PowerShell script for automated setup.

#### Prerequisites
- PowerShell 7.x or later
- SharePoint Administrator or Global Administrator credentials
- Internet connection

#### Steps

1. Open PowerShell 7 as administrator

2. Navigate to this directory:
   ```powershell
   cd "C:\path\to\Allfiles\Lab-3A"
   ```

3. Run the setup script:
   ```powershell
   .\lab-3a-setup.ps1 -TenantUrl "https://YOUR-TENANT.sharepoint.com"
   ```
   Replace `YOUR-TENANT` with your actual tenant name.

4. Authenticate when prompted using Global Administrator credentials

5. Wait for the script to complete (approximately 2-3 minutes)

#### What the Script Does
- ✓ Creates a SharePoint communication site at `/sites/sc500-ai-datastore`
- ✓ Configures site permissions to share with "Everyone except external users"
- ✓ Uploads three sample documents:
  - `Employee_Salary_Report_2026.txt` (HR data with SSNs, salaries, PII)
  - `Q2_Financial_Statement_2026.txt` (Financial data with bank accounts, credit cards)
  - `HR_Benefits_Guide_2026.txt` (Compensation data, personal information)
- ✓ Ensures no sensitivity labels are applied

### Option 2: Manual Setup

If you prefer not to use the PowerShell script, follow these manual steps:

#### 1. Create SharePoint Site

1. Sign in to [SharePoint admin center](https://admin.microsoft.com/sharepoint)
2. Select **Sites** > **Active sites**
3. Click **Create** > **Communication site**
4. Configure:
   - **Site name**: SC500 AI Data Store
   - **Site address**: `/sites/sc500-ai-datastore`
   - **Description**: Pre-seeded SharePoint site for SC-500 Lab 3A
5. Click **Finish**

#### 2. Configure Oversharing Permissions

1. Navigate to the new site: `https://YOUR-TENANT.sharepoint.com/sites/sc500-ai-datastore`
2. Click the **Settings** gear icon > **Site permissions**
3. Click **Share site**
4. In the share dialog:
   - Enter **Everyone except external users**
   - Set permission level to **Read**
   - Uncheck "Send email"
5. Click **Share**

#### 3. Upload Sample Documents

1. Go to the **Documents** library on the site
2. Create three text documents with the following content:

**Employee_Salary_Report_2026.txt**:
```
CONFIDENTIAL - HUMAN RESOURCES

Employee Salary Report - Q2 2026

Employee ID: 10234
Name: Sarah Johnson
SSN: 123-45-6789
Department: Engineering
Position: Senior Software Engineer
Salary: $145,000
Bonus: $15,000

Employee ID: 10567
Name: Michael Chen
SSN: 987-65-4321
Department: Finance
Position: Financial Analyst
Salary: $95,000

This document contains personally identifiable information and financial data.
```

**Q2_Financial_Statement_2026.txt**:
```
CONFIDENTIAL - FINANCIAL REPORT

Quarterly Financial Statement - Q2 2026

Revenue: $4.5M
Operating Expenses: $2.1M
Net Income: $2.4M

Bank Account: 1234-5678-9012-3456
Routing Number: 123456789
Credit Line: $1,000,000

This document contains sensitive financial information.
```

**HR_Benefits_Guide_2026.txt**:
```
INTERNAL USE ONLY

Employee Benefits Guide 2026

Salary Ranges by Level:
  Level 1 (Entry): $55,000 - $70,000
  Level 2 (Mid): $75,000 - $95,000
  Level 3 (Senior): $100,000 - $140,000

This document contains compensation data and personal information.
```

3. Upload all three files to the Documents library
4. **Important**: Do NOT apply sensitivity labels to these documents

#### 4. Generate Copilot Interaction Signals (Optional)

To create realistic Copilot interaction data:

1. Wait 1-2 hours after creating the site for it to be indexed
2. Use Microsoft 365 Copilot to query the site content:
   - "Summarize the employee salary report in the sc500-ai-datastore site"
   - "What financial information is stored in sc500-ai-datastore?"
   - "Show me HR documents from the ai-datastore site"
3. These queries will generate interaction signals visible in Purview DSPM

## Post-Setup Timeline

After completing setup:

| Timeframe | What Happens |
|-----------|--------------|
| Immediate | Site is accessible to all users |
| 1-2 hours | SharePoint indexing completes |
| 4-6 hours | Purview begins initial scan |
| 24-48 hours | Full DSPM signals appear in dashboard |

**Note**: For lab environments, you may proceed with the lab exercises immediately. Some DSPM signals may take time to populate fully, but the site structure and permissions will be evaluable immediately.

## Troubleshooting

### PowerShell Module Issues

If the script fails to install `PnP.PowerShell`:

```powershell
# Manually install the module
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber

# If that fails, use this alternative:
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -SkipPublisherCheck
```

### Permission Issues

If you receive "Access Denied" errors:
- Verify you are a **SharePoint Administrator** or **Global Administrator**
- Ensure you're connecting to the correct tenant URL
- Try running PowerShell as Administrator

### Site Already Exists

If the site already exists from a previous lab run:
- The script will prompt you to update the existing site
- Or, manually delete the site from SharePoint admin center first
- Or, use a different site URL in the script parameters

## Why No ARM Template?

Unlike Labs 2A, 2B, and 2C which use Azure Resource Manager (ARM) JSON templates, Lab 3A cannot use ARM templates because:

- **SharePoint sites are Microsoft 365 resources**, not Azure resources
- ARM templates only deploy Azure resources (VMs, storage, networks, etc.)
- SharePoint configuration requires either PowerShell (PnP.PowerShell) or Microsoft Graph API
- This is why Lab 3A uses a `.ps1` script instead of a `.json` template

## Cleanup

To remove the site after lab completion:

### PowerShell Method
```powershell
Connect-PnPOnline -Url "https://YOUR-TENANT-admin.sharepoint.com" -Interactive
Remove-PnPTenantSite -Url "https://YOUR-TENANT.sharepoint.com/sites/sc500-ai-datastore" -Force
```

### Manual Method
1. Go to [SharePoint admin center](https://admin.microsoft.com/sharepoint)
2. Select **Sites** > **Active sites**
3. Find **sc500-ai-datastore**
4. Click the checkbox, then click **Delete**
5. Confirm deletion

## Support

For issues or questions:
- Review the lab instructions in `Instructions\Labs\Lab-3A-Purview-AI-Risks.md`
- Check PowerShell execution policy: `Get-ExecutionPolicy` (should be RemoteSigned or Unrestricted)
- Verify tenant URL format: `https://TENANT.sharepoint.com` (no trailing slash)

---

**Lab**: SC-500 Lab 3A - Identify AI Data Risks with Microsoft Purview  
**Setup Type**: PowerShell (SharePoint Online)  
**Estimated Setup Time**: 3-5 minutes  
**DSPM Signal Availability**: 24-48 hours
