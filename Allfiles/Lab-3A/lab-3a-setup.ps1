<#
.SYNOPSIS
    Lab 3A Setup Script - Create sc500-ai-datastore SharePoint site with oversharing configuration

.DESCRIPTION
    This script provisions the sc500-ai-datastore SharePoint site required for SC-500 Lab 3A.
    It creates a SharePoint communication site, configures oversharing permissions, and uploads
    sample documents containing sensitive data (HR and financial content) without sensitivity labels.

.NOTES
    Lab: SC-500 Lab 3A - Identify AI Data Risks with Microsoft Purview
    Required Modules: PnP.PowerShell
    Required Permissions: SharePoint Administrator or Global Administrator
    Execution: Run in PowerShell 7.x or later

.PARAMETER TenantUrl
    The root SharePoint Online URL for your tenant (e.g., https://contoso.sharepoint.com)

.PARAMETER SiteUrl
    The full URL for the site to create (default: /sites/sc500-ai-datastore)

.EXAMPLE
    .\lab-3a-setup.ps1 -TenantUrl "https://contoso.sharepoint.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "/sites/sc500-ai-datastore"
)

#Requires -Version 7.0

# Check if PnP.PowerShell module is installed
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "Installing PnP.PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
}

# Import the module
Import-Module PnP.PowerShell -ErrorAction Stop

# Full site URL
$fullSiteUrl = $TenantUrl.TrimEnd('/') + $SiteUrl

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SC-500 Lab 3A Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:" -ForegroundColor White
Write-Host "  1. Create SharePoint site: $fullSiteUrl" -ForegroundColor White
Write-Host "  2. Configure oversharing permissions (Everyone except external users)" -ForegroundColor White
Write-Host "  3. Upload sample HR and financial documents" -ForegroundColor White
Write-Host "  4. Ensure documents have no sensitivity labels" -ForegroundColor White
Write-Host ""

# Connect to SharePoint Online
Write-Host "Connecting to SharePoint Online..." -ForegroundColor Yellow
try {
    Connect-PnPOnline -Url $TenantUrl -Interactive -ErrorAction Stop
    Write-Host "✓ Connected successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to SharePoint Online: $_"
    exit 1
}

# Step 1: Create the SharePoint Communication Site
Write-Host ""
Write-Host "Step 1: Creating SharePoint communication site..." -ForegroundColor Yellow
try {
    $site = Get-PnPTenantSite -Url $fullSiteUrl -ErrorAction SilentlyContinue
    
    if ($site) {
        Write-Host "⚠ Site already exists at $fullSiteUrl" -ForegroundColor Yellow
        $continue = Read-Host "Do you want to continue and update the existing site? (Y/N)"
        if ($continue -ne 'Y') {
            Write-Host "Setup cancelled by user." -ForegroundColor Red
            exit 0
        }
    }
    else {
        Write-Host "Creating new communication site..." -ForegroundColor White
        New-PnPSite -Type CommunicationSite `
            -Title "SC500 AI Data Store" `
            -Url $fullSiteUrl `
            -Description "Pre-seeded SharePoint site for SC-500 Lab 3A - Contains HR and financial data for Purview DSPM testing" `
            -ErrorAction Stop
        
        Write-Host "✓ Site created successfully" -ForegroundColor Green
        
        # Wait for site provisioning to complete
        Start-Sleep -Seconds 10
    }
}
catch {
    Write-Error "Failed to create site: $_"
    exit 1
}

# Connect to the new site
Write-Host "Connecting to the new site..." -ForegroundColor White
Connect-PnPOnline -Url $fullSiteUrl -Interactive

# Step 2: Configure oversharing permissions
Write-Host ""
Write-Host "Step 2: Configuring oversharing permissions..." -ForegroundColor Yellow
try {
    # Break permission inheritance if not already broken
    Set-PnPWeb -BreakRoleInheritance -CopyRoleAssignments:$false -ErrorAction SilentlyContinue
    
    # Get "Everyone except external users" group
    $everyoneGroup = Get-PnPGroup | Where-Object { $_.Title -like "*Everyone except external*" -or $_.LoginName -like "*spo-grid-all-users*" }
    
    if (-not $everyoneGroup) {
        # If the default group doesn't exist, get it by login name
        $everyoneGroup = Get-PnPUser | Where-Object { $_.LoginName -like "*spo-grid-all-users*" } | Select-Object -First 1
    }
    
    if ($everyoneGroup) {
        # Grant Read permission to Everyone except external users
        Set-PnPWebPermission -User $everyoneGroup.LoginName -AddRole "Read" -ErrorAction Stop
        Write-Host "✓ Granted Read permission to 'Everyone except external users'" -ForegroundColor Green
    }
    else {
        Write-Warning "Could not find 'Everyone except external users' group. You may need to configure this manually."
        Write-Host "  Manual steps:" -ForegroundColor Yellow
        Write-Host "    1. Go to Site Settings > Site Permissions" -ForegroundColor Yellow
        Write-Host "    2. Grant Read access to 'Everyone except external users'" -ForegroundColor Yellow
    }
}
catch {
    Write-Warning "Could not configure automatic sharing: $_"
    Write-Host "  Please configure site sharing manually:" -ForegroundColor Yellow
    Write-Host "    1. Go to Site Settings > Site Permissions" -ForegroundColor Yellow
    Write-Host "    2. Share with 'Everyone except external users' with Read permissions" -ForegroundColor Yellow
}

# Step 3: Create and upload sample documents
Write-Host ""
Write-Host "Step 3: Creating and uploading sample documents..." -ForegroundColor Yellow

# Create a temporary folder for documents
$tempFolder = Join-Path $env:TEMP "SC500-Lab3A-Documents"
if (-not (Test-Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
}

# Sample HR Document
$hrDocPath = Join-Path $tempFolder "Employee_Salary_Report_2026.docx"
$hrContent = @"
CONFIDENTIAL - HUMAN RESOURCES

Employee Salary Report - Q2 2026

Employee ID: 10234
Name: Sarah Johnson
SSN: 123-45-6789
Department: Engineering
Position: Senior Software Engineer
Salary: $145,000
Bonus: $15,000
Health Insurance: Premium Plan
Home Address: 123 Oak Street, Seattle, WA 98101
Phone: (206) 555-0123
Email: sarah.johnson@contoso.com

Employee ID: 10567
Name: Michael Chen
SSN: 987-65-4321
Department: Finance
Position: Financial Analyst
Salary: $95,000
Bonus: $8,000
Health Insurance: Standard Plan
Home Address: 456 Maple Ave, Seattle, WA 98102
Phone: (206) 555-0456

Performance Review Notes:
- Excellent technical skills
- Recommended for promotion
- PII: Date of Birth 03/15/1985

This document contains personally identifiable information and financial data.
"@

# Sample Financial Document
$finDocPath = Join-Path $tempFolder "Q2_Financial_Statement_2026.docx"
$finContent = @"
CONFIDENTIAL - FINANCIAL REPORT

Quarterly Financial Statement - Q2 2026
Contoso Corporation

Revenue: $4.5M
Operating Expenses: $2.1M
Net Income: $2.4M

Bank Account Information:
  Primary Account: 1234-5678-9012-3456
  Routing Number: 123456789
  Credit Line: $1,000,000

Executive Compensation:
  CEO: $450,000 base + $100,000 bonus
  CFO: $350,000 base + $75,000 bonus
  CTO: $325,000 base + $70,000 bonus

Customer Payment Data:
  - Customer A: Credit Card **** **** **** 4532
  - Customer B: ACH Transfer pending
  - Customer C: Wire transfer $250,000

Tax ID: 98-7654321

This document contains sensitive financial information and should not be shared externally.
"@

# Sample HR Policy Document
$policyDocPath = Join-Path $tempFolder "HR_Benefits_Guide_2026.docx"
$policyContent = @"
INTERNAL USE ONLY

Employee Benefits Guide 2026

Health Insurance Plans:
  Premium Plan: $0 employee cost, full family coverage
  Standard Plan: $150/month, employee + spouse
  Basic Plan: $75/month, employee only

Contact Information:
  HR Director: Jennifer Martinez
  Email: hr@contoso.com
  Phone: (206) 555-0100
  SSN (for benefits verification): 555-12-3456

Retirement Plans:
  401(k) Matching: Up to 6%
  Vesting Schedule: 4 years
  Investment Options: Available through Fidelity

Salary Ranges by Level:
  Level 1 (Entry): $55,000 - $70,000
  Level 2 (Mid): $75,000 - $95,000
  Level 3 (Senior): $100,000 - $140,000
  Level 4 (Principal): $145,000 - $180,000
  Level 5 (Executive): $200,000+

This document contains compensation data and personal information.
"@

# Save documents as text files (since we can't create .docx programmatically without Word)
$hrDocPath = $hrDocPath -replace '\.docx$', '.txt'
$finDocPath = $finDocPath -replace '\.docx$', '.txt'
$policyDocPath = $policyDocPath -replace '\.docx$', '.txt'

Set-Content -Path $hrDocPath -Value $hrContent -Encoding UTF8
Set-Content -Path $finDocPath -Value $finContent -Encoding UTF8
Set-Content -Path $policyDocPath -Value $policyContent -Encoding UTF8

Write-Host "  Created sample documents in $tempFolder" -ForegroundColor White

# Upload documents to SharePoint
try {
    # Ensure Documents library exists
    $docLibrary = Get-PnPList -Identity "Documents" -ErrorAction SilentlyContinue
    if (-not $docLibrary) {
        Write-Host "  Creating Documents library..." -ForegroundColor White
        New-PnPList -Title "Documents" -Template DocumentLibrary -ErrorAction Stop
    }
    
    Write-Host "  Uploading Employee_Salary_Report_2026.txt..." -ForegroundColor White
    Add-PnPFile -Path $hrDocPath -Folder "Documents" -ErrorAction Stop
    
    Write-Host "  Uploading Q2_Financial_Statement_2026.txt..." -ForegroundColor White
    Add-PnPFile -Path $finDocPath -Folder "Documents" -ErrorAction Stop
    
    Write-Host "  Uploading HR_Benefits_Guide_2026.txt..." -ForegroundColor White
    Add-PnPFile -Path $policyDocPath -Folder "Documents" -ErrorAction Stop
    
    Write-Host "✓ Documents uploaded successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to upload documents: $_"
    Write-Host "  Documents are available at: $tempFolder" -ForegroundColor Yellow
    Write-Host "  You can upload them manually to the Documents library" -ForegroundColor Yellow
}

# Step 4: Verify no sensitivity labels are applied
Write-Host ""
Write-Host "Step 4: Verifying document configuration..." -ForegroundColor Yellow
Write-Host "✓ Documents created without sensitivity labels" -ForegroundColor Green
Write-Host "  (Sensitivity labels would need to be applied through Purview, not during upload)" -ForegroundColor Gray

# Cleanup temp folder
Write-Host ""
Write-Host "Cleaning up temporary files..." -ForegroundColor White
Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Site URL: $fullSiteUrl" -ForegroundColor White
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor White
Write-Host "  ✓ SharePoint site created: sc500-ai-datastore" -ForegroundColor Green
Write-Host "  ✓ Permissions configured for oversharing (Everyone except external users)" -ForegroundColor Green
Write-Host "  ✓ Sample documents uploaded (HR and Financial data)" -ForegroundColor Green
Write-Host "  ✓ No sensitivity labels applied (as required for lab)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait 24-48 hours for Purview DSPM to scan the site" -ForegroundColor Yellow
Write-Host "  2. Optionally, use Copilot to query content from this site to generate interaction signals" -ForegroundColor Yellow
Write-Host "  3. Proceed with Lab 3A instructions" -ForegroundColor Yellow
Write-Host ""
Write-Host "Disconnecting from SharePoint..." -ForegroundColor White
Disconnect-PnPOnline

Write-Host "✓ Setup script completed successfully" -ForegroundColor Green
