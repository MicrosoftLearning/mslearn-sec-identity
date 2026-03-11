
## Lab 01 - Enable Multifactor authentication registration

**Lab topics covered:**
- MFA Registration
- Microsoft Authenticator setup

#### Lab scenario
Every company and every user should be protected by two-factor authentication.  With the rise of both phishing attacks and social engineering, it is crucial that you move away from a single password to protect your business.  This lab will show how to start your company on that process, without blocking access to any work systems.

#### Estimated time: 10 minutes
## Exercise - Review, enable, and test registration for Multifactor authentication
### Task 1 - Review and enable Multifactor authentication for Delia Dennis

1.	Launch the browser. Sign into `https://entra.microsoft.com` with a **MOD Admin** account.
2.	In the **Identity** menu on the left side of the screen open **Protection** then choose **Identity Protection**.
3.	Select **Multifactor authentication registration policy** from the newly opened screen.

- **Note** - There is a pre-built **MFA registration policy** available.  It is configured to require All Users to complete the Microsoft Entra ID multifactor authentication registration process.  It is disabled by default.  You can modify the target audience to be a specific user or group for testing purposes.  You can choose to enable and disable as needed.  This policy does not require people to use MFA, just to configure themselves for MFA.  For the purposes of this lab, we are only doing to require one person to register.

4.	Select **All Users**, to open up the Include / Exclude dialog.
5.	On the Include tab, mark the **Select individuals and groups** item.
6.	Choose **Delia Dennis** from the list of users and groups that opens.
7.	The use the **Select** button to finalize the choice.
8.	Select the **Exclude tab**.

- **Note** - From the Exclude tab you could select specific users or groups that you don't want the policy to apply to.  Use this to protect certain accounts like Recovery or Break-Glass Accounts that you have set up for emergency purposes.  Those accounts should always be protected by using specific rules.

9. Select the **0 users and groups selected** item.
10. Mark your **Mod Administrator** account to exclude.
11. Use the **Select** to approve the choice.
12.	Mark the **Enabled** option at the bottom of the screen.
13.	Then select **Save**.

### Task 2 - Test Delia Dennis' login process.

1.	Open a new InPrivate window in your browser.
2.	Go to either https://entra.microsoft.com or https://portal.azure.com. 
3.	Sign is as **Delia Dennis:**

| Prompt | Value |
| :--- | :--- |
| Username | DeliaD@<your domain> |
| | Get your domain from the resources tab. Example: DeliaD@**LODS#####.onmicrosoft.com** |
| Password | Use the supplied user password |

- **Note** - If prompted to change your password, a **Pro Tip** is to grab one of the passwords from the **Resources tab**.  These passwords are always available and are secure, complex, and meet all login requirements.

4.	After login, you will be prompted to provide more information - **Register for MFA**.
5.	Select **Next**.
6.	Install the **Microsoft Authenticator** app if you don't have it already. Then select **Next**.
7.	Choose **Next** on the **Set up your account** screen.
8.	Open the **Microsoft Authenticator** app on your **phone**.
9.	Select the **+** in the upper right corner, then choose **Work or school account**.
10.	Select **Scan QR code**.
11.	Use the phone's camera to scan the QR code provide on your screen.
12.	You should see **Delia's account** added to Microsoft Authenticator in a few seconds.
13.	On the **computer screen**, select **Next**.
14.	On the Microsoft **Authenticator** app, enter the provided numerical code, and sign-in as requested.
15.	You should get a Notification approved message from your login.
16.	Select **Next**, then select **Done** on the success screen.

You are now logged in, and you have MFA configured.  You will not be required to use MFA to log in.  The goal was to get users to install the MFA software, and configure the MFA login account, without preventing access to their software.  This step allows you to roll out MFA with minimal impact to your users.

### Task Verification - Log in as Delia Dennis and note you are not prompted for MFA

1.	Open an InPrivate browser window.
2.	Lauch the Azure Portal at https://portal.azure.com
3.	Log in with as **DeliaD** with the password created earlier.

- **Note** - You will log in without needing MFA, although you did register for MFA in the previous task.

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/All-MOC/master/MOC/@lab.LanguageCode/CongratulationsLab.md)

===

# Ignite Lab 456

## Lab 02 - Require MFA for connection to Cloud Admin sites

**Lab topics covered:**
- Enabling MFA
- Conditional Access MFA-Policy	

#### Lab scenario

Your company is starting to launch a series of cloud applications that have access to customer data, and other important resources.  Users will need to connect to Microsoft Entra and Azure portals to get them set up.  You want to ensure that users connect using MFA secured account.

#### Estimated Time: 10 minutes
## Exercise 1 - Require MFA for users connecting to Microsoft Cloud Admin portals
### Task-1 - Create Conditional Access policy to require MFA

1. Sign into https://entra.microsoft.com if you are not already.
2. Open **Protection** from the menu on the left.
3. Select **Conditional Access** from the newly opened menu.
4. Select the **+ Create new policy** from the top of the page.
5. **Create a Conditional Access Policy** with the following values:

| Field | Value to use |
| :--- | :--- |
| Name | `Require MFA for portals` |
|Assignments: | Include Tab |
| | 1) Select **0 users and groups selected** |
| | 2) Mark **Select users and groups** |
| | 3) Mark **Users and groups** |
| | 4) Choose **Delia Dennis** from the list of users |
| | 5) Use the **Select** button to enter your choices |
|Assignments: | Exclude Tab |
| | 1) Select **Users and groups** |
| | 2) Mark **Select users and groups** |
| | 4) Choose **Mod Administrator** from the list of users |
| | 5) Use the **Select** button to enter your choices |
|Target resources: | |
| | 1) Choose the **No target resources selected** item |
| | 2) Mark the **Select resources** item |
| | 3) Choose **None** under the **Select** section |
| | 4) From the menu that open choose **Microsoft Admin Portals** |
| | 5) Use the **Select** button to confirm your choices |
| Network | Skip |
| Conditions | Skip |
| Access controls: | |
| | 1) In the **Grant** section select **0 controls selected** |
| | 2) Mark the **Require multifactor authentication** box |
| | 3) Ensure **Require all selected controls** is chosen |
| | 4) Use the **Select** button to confirm your choices |
| Session | Skip |

6. Set the Enable policy to **On**.
7. Select the **Create** button.

### Task 2 - Log in as Delia Dennis to verify MFA requirement

1. Open a new InPrivate browser window.
2. Go to `https://www.office.com`.
3. Log in a **DeliaD** with the password created earlier.

- **Note** - Because you are going to a web site, you only needed your password, not MFA.

4. In the browser address bar, go to https://entra.microsoft.com to launch the **Entra admin center**.
5. Follow the on-screen instructions to confirm your MFA login with DeliaD.

---

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/All-MOC/master/MOC/@lab.LanguageCode/CongratulationsEnd.md)

===

# Ignite Lab 456

## Lab 03 - Enable Phishing resistant MFA for login

**Lab topics covered:**
- Phishing resistant MFA
- Authentication methods
- Authentication strengths
- Conditional Access	

#### Lab scenario

You have MFA registration completed and have started to require MFA for login.  However, you are hearing that your company's MFA protection could be even better.  You can strengthen your MFA requirements to make users log in with Phishing resistant MFA.

#### Estimated Time: 15 minutes
## Exercise 1 - Enable phishing resistant MFA and apply it to users
### Task 1 - Enable Passkey (FIDO2)

1. If not already logged in, connect to https://entra.microsoft.com
2. Select **Identity** then select **Protection** from the menu on the left.
3. From the Protection portion of the menu on the left choose **Authentication methods**.
3. Select **Policies** from the newly opened screen.
4. Select **Passkey (FIDO2)**.
5. Use the slider to **Enable** to Passkey (FIDO2) authentication method.
6. Select **Save**.

You have now made the phishing resistant option to use Passkeys available in your tenant.

### Task 2 - Use Authentication methods to create a Passkey (FIDO2) strong authentication

1. From the **Protection** portion of the menu on the left choose **Authentication methods**.
2. Select **Authentication strengths**.
3. Choose **+ New authentication strength** from the top of the dialog.
4. Enter a name and description:

| Field | Value |
| :--- | :--- |
| Name | `Ignite phishing resistant MFA` |
| Description | `Lab created authentication strength forcing users to log in with phishing resistant MFA.` |

5. Mark **Passkeys (FIDO2)**, in the list.
6. Select the **Advanced options** item under **Passkeys (FIDO2)**.
7. Mark the **Microsoft Authenticator (preview)** item.
8. Select **Save**.
9. Select **Next**.  This opens the **New authentication strength** dialog for Review.
10. Select **Create**.

You have created a new Authentication strength that can be used with Conditional access.  There is a Built-in authentication strength we could have used, however in this lab, we want to see how granular of a customization you can do.  When deploying in your business environment, you can pick the authentication methods and strengths that aligns to your security needs.

### Task 3 - Add Authentication strength to your Conditional Access policy

1. Open the **Protection** portion of the menu, then choose **Conditional Access**.
2. Select **Policies** from the screen that opens.
3. Choose the **Require MFA for portals** policy we created earlier.
4. Under **Access controls** in the Grant section select the **1 control selected** item.
4. **Unmark** the **Require multifactor authentication**.
5. **Mark** the **Require authentication strength**.
6. Use the dropdown to select the **Ignite Phishing resistant MFA** strength you created in the previous task.

- **Note** - if the new authentication strength does not show up in the dropdown. Go to the upper-right corner and sign-out of the admin portal. Then close your browser, wait a minute. Then you can open the browser, and connect to `https://entra.microsoft.com` and log in as MOD Admin.  Start at Task 3 again.  It takes a few minutes for the new authentication strength to show up.

7. Use the **Select** button to exit the screen.
8. Ensure the **Enable policy** is set to **On**.
9. Select **Save**.

At this point, you have set up a policy using Conditional Access to require users to configure and log in with a Passkey, which is a phishing resistant login MFA method.  Reminder that we custom built the Authentication strength, so you could pick exactly what security options to want to use.  You could use the built in phishing resistant strength.

### Task 4 - Configure a passkey for Delia's log in - Passkey (FIDO2)

## IMPORTANT - Creating a passkey on the Microsoft Authenticator app requires a Bluetooth connection between your phone and computer.  Virtual machines do not support a Bluetooth connection.  So, perform the next few steps on the browser on you lab PC; not within the lab environment. 

1. Open an **InPrivate** browsing window.
2. Connect to `http://portal.azure.com`.
3. Log in as **DeliaD**.

- **Note** - you will be prompted for username and password we used previously in the lab.

4.	Select **Next** when the screen that says **your company needs more information** comes up.
5.	You should be prompted to **log in with MFA** to securely confirm your identity.
6.	Select **Yes** on the **Stay signed** in screen.

- **Note** - You will be prompted to build out your Passkey.

7.	Select **Next** on the **Create your passkey in Microsoft Authenticator** screen.

- **Recommendation** - Many Microsoft Authentication apps are not enabled to CREATE a Passkey.  To be safe we are going to use the Bluetooth method. When the **Complete the setup in Microsoft Authenticator** dialog appears, we will select "Having trouble?".

8. Select **Having trouble?**.
9. On the Having trouble screen, select **create your passkey a different way** text.
10.	Choose **iPhone** (or Android) from the list.

- **Phone** - pick the type of you phone you have.  For this lab we are assuming an iPhone, but either should work.

11.	Follow the steps on the **Turn on Microsoft Authenticator as passkey provider** that appear on your screen. 
12.	Select **Continue** when you are done.
13.	**Read** the **Get your devices ready** screen.

- **Note** - at this point the setup will use Bluetooth to set up a secure connection between your PC and your phone.  This allows for a secure confirmation, transfer, and storage of you new Passkey.

14.	Select **I'm ready** to proceed.
15.	Make sure your **Phone type** is highlighted, then select **Next**.
16.	Open your **phone camera** and **scan the QR-code**.

- **Note** - This will set up the secure Bluetooth link between your computer and phone.

17.	In the camera screen, choose **Save a Passkey** on your phone.
18.	Then select **Continue** on your phone.
19.	You will be prompted to enter for Microsoft Authenticator app passcode.
20.	On your PC, select **OK**.
21.	On the **Name your passkey** screen, select **Next**.

- **Note** - In this lab environment, the name your passkey screen will sometimes hang.  This should not happen in a live environment.  If you get a spinning wait symbol for a minute; you can close your browser window.  You have completed the creation and save process for the Passkey.

22.	**Close the camera** on your phone.
23. **Close your InPrivate browser** on your PC.

You have now successfully created and saved your Passkey on the phone.

### Task 5 - Log in with Phishing resistant MFA - Passkey (FIDO2)

## Reminder that Bluetooth is required for the login to work; please continue to use a browser outside of your lab environment on the PC.

1. Open a new **InPrivate** browser.
2. Connect to `https://portal.azure.com`.
3. Log in as DeliaD with the username and password provided.
4. On the **Sign in with your passkey** screen select **iPhone, iPad, or Android**.
5. Select **Next**.
6. Open your **Camera** on your phone, and **Scan the QR-code** provided on the screen.
7. Select **Sign in with a passkey**.
8. Select **Continue**.
9. Enter your **Authenticator login**.
10. You may close your camera on your phone, you phone is no longer needed.
11. On you PC, choose **Yes** for the **Stay signed in?** dialog.

You are now successfully logged into your computer with a Phishing resistant MFA sign-in.

---

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/All-MOC/master/MOC/@lab.LanguageCode/CongratulationsEnd.md)

===

# Ignite Lab 456

## Lab 04 - Configure and enable User Risk and Sign-in Risk policies

**Lab topics covered:**
- User risk policy
- Sign-in policy
- Identity protection
- Conditional Access

### Lab scenario
Your company has now set up a very secure login process with Phishing resistant MFA.  Now you want to think about protecting your infrastructure and data when your system notices suspicious login behavior. What if we see a user trying to log into your tools from two location as the same time. Or if Microsoft recognizes a username and password pair that has been found on the web. As an additional layer of security, you need to enable and configure your Microsoft Entra organization's sign in and user risk policies.

#### Estimated time: 10 minutes
## Exercise 1 - Configure and enable general User risk and Sign-in risk policies
### Task 1 - Configure the User risk in Identity protection
1.	Sign in to the `https://entra.microsoft.com` as a **MOD admin**.
2.	On menu, under **Identity**, select **Protection**.
3.	Open **Identity protection**.
4.	In the Identity protection page, select **User risk policy**.
5.	Under **Assignments**, select **All users** and review the available options.

- **Note** - You can select from All users or Select individuals and groups if limiting your rollout.

6.	Additionally, you can choose to **Exclude** users from the policy.
7.	Under **User risk**, select **Low and above**.
8.	Select **High** and then select **Done**.
9.	Under the **Controls** section, select **Block access**.
10.	In the Access pane, **Require password change** checkbox and then select **Done**.
11.	Under **Policy enforcement**, select **Enable** and then select **Save**.

### Task 2 - Configure the Sign-in risk in Identity protection
1.	In the Identity protection page, select **Sign-in risk policy**.
2.	Under **Assignments**, select **All users** and review the available options.

- **Note** - When you are rolling out the policy, you can align to the specific needs.

6.	Additionally, you can choose to **Exclude** users from the policy.
7.	Under **Sign-in risk**, select **Low and above**.
8.	Select **High** and then select **Done**.
9.	Under the **Controls** section, select **Block access**.
10.	In the Access pane, **Require multifactor authentication** checkbox and then select **Done**.
11.	Under **Policy enforcement**, select **Enable** and then select **Save**.

You have now set up two global policies to look for risky user and sign-in behaviors and set appropriate actions to protect your company.  However, there is another way you can apply User risk and Sign-in risk data. Let's take a look at Conditional Access.

## Exercise 2 - Use a Conditional Access policy to apply User and Sign-in risk policies
### Task 1 - Configure a Conditional Access policy that incorporates User and Sign-in risk

1. If you are not already logged into Entra admin center, connect now to https://entra.microsoft.com.
2. From the **Identity** portion of the menu, open the **Protection** section.
3. From **Protection** select **Conditional Access**.
4. Select **Policies**.
5. Choose **+ New policy** from the top of the screen.
6. Use the following data to fill out the policy:

| Field | Value |
| :--- | :--- |
| Name | `Risk conditions policy` |
| Assignments | Grady Archie |
| Target resources | Microsoft admin portals |
| Network | skip this setting |
| Conditions | |
| | 1) Select the **0 conditions selected** |
| | 2) Under **User risk** select **Not configured** |
| | 3) Set Configure = **Yes**. Then select **Medium** and **High** and then **Done** |
| | 4) Under **Sign-in risk** select **Not configured** |
| | 5) Set Configure = **Yes**. Then select **High** and then **Done** |
| | 6) Note the other conditions that you could choose to enforce |
| Access Controls | |
| | 1) Select **0 controls selected** under **Grant** |
| | 2) Mark **Require MFA** |
| | 3) Choose **Select** |
| Enable Policy | **On** |

7. Select **Create**.

Notice how granular and specific you can be about enforcing access.  Think of a scenario where you have a new Generative AI application, that can access the customer data your company owns.  You can build out a specific policy that limits access to given user and requires them to have limited to no security risks.

---

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/All-MOC/master/MOC/@lab.LanguageCode/CongratulationsEnd.md)

===

# Ignite Lab 456

## Lab 05 - Add Terms of Use and acceptance reporting

**Lab topics covered:**
- Terms of Use
- Identity governance

### Lab scenario
Microsoft Entra terms of use (ToU) policies provide a simple method that organizations can use to present information to both internal and external users. This presentation of terms and sign-off ensures users see relevant disclaimers for legal or compliance requirements. You must create and enforce a ToU policy for your organization.

#### Estimated time: 20 minutes
## Exercise 1 - Set up a Term of Use and test them
### Task 1 - Add terms of use

**FYI** - A simple Terms of User (ToU) document has been provided for you in the labs folder.

1. Open a browser and sign in to `https://entra.microsoft.com` using the MOD Admin account.
2.	Open **Identity Governance** in the left navigation menu.
3. From the **Identity Governance** menu, select **Entitlement management**.
4. Select **Terms of use**.
5. On the Terms of use page, select **+ New terms**.
6.	In the Name box, enter `Terms of use for Contoso`.

- **Note** - This is the terms of use that will be used in the admin portals.

7.	Select the **Terms of use** document box, **browse** folder to select your terms of use PDF.

- **Sample ToU File Provided** - browse to the `f:\AllFiles\Labs\Lab26` to get a sample Terms-of-User PDF document for use in this lab.

8. Choose the **Contoso TermsofUse.pdf** file and select **Open**.
9. Choose **English** as the default language.
10.	In the Display name box, enter `Contoso Terms of Use`.
11.	Confirm you have the correct values.

- **Note** - The language option allows you to upload multiple terms of use, each with a different language. The version of the terms of use that an end user will see will be based on their browser preferences.

12. Set **Require users to expand terms of use** to **On**.
13.	Set **Require users to consent on every device** to **Off**.
14.	Set **Expire contents** to **Off**.
15. Set **Duration before re-acceptance** to **30 days**.
16.	Under **Conditional Access**, select **Custom policy**.
17.	When complete, select **Create**.

### Task 2 - Create the associated Conditional Access ToU policy

**FYI** - When the terms of use is created, you will automatically be redirected to the Conditional access policy page.

1. On the page **New Conditional Access policy page, create a policy with the following values:
| Field | Value |
| :--- | :--- |
| Name | `Enforce ToU` |
| Assignments | select **Adele Vance** on the Include tab |
| Select Target resources | **All resources (formerly All cloud apps)** |
| Network | Skip |
| Conditions | Skip |
| Access controls | |
| | 1) Choose **0 controls selected** from the **Grant** section |
| | 2) Mark the box next to **Terms of User for Contoso** |
| | 3) Mark **Require all the selected controls** |
| | Choose the **Select** button |

2.	Set **Enable policy** to **On**.
3.	When complete, select **Create**.

### Task 2 - Log in as Adele

1.	Open a new **InPrivate browser** window.
2.	Connect to `https://portal.azure.com`.
3.	Log in as Adele:
| Setting | Value to enter |
| :--- | :--- |
| User Name | AdeleV@ <<your domain name>>.onmicrosoft.com |
| Password | Enter the password provided |

4.	If prompted - Validate Adele's login with the MFA request.
5.	Select **Accept** without opening the ToU.

- **Note**- Notice you are prompted that you have to read the ToU.  This was a value we picked when setting up the ToU.

6. **View the Terms of Use** document.
7. Select **Accept**.
8. Choose **Yes** to stay logged in.

### Task 3 - View ToU report

The Terms of use page shows a count of the users who have accepted and declined. These counts and who accepted/declined are stored for the life of the terms of use.

1. Open **Identity Governance** in Microsoft Entra admin center.
2. Select **Entitlement management** then select **Terms of use**.
3. Locate the **Terms of Use for Contoso** we created in the previous tasks.
4. Notice that you should have 1 **Current Accepted** user.

- **Note** - It can take up to 10 minutes for the acceptance to register in the report.

5. Select the **number value** under **Current Accepted**.
6. View the name of the users who have accepted.

---

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/All-MOC/master/MOC/@lab.LanguageCode/CongratulationsEnd.md)

===

# Ignite Lab 456

## Lab 05 - Explore Continuous Access Evaluation

**Lab topics covered:**
- Continuous Access Evaluation (CAE)
- Session conditions in Conditional Access

### Lab scenario
Your company is about to launch a new AI application.  Due to current regulations, the application can only be run in United States.  Create a policy that will prevent a user from launching the app from another location; or moving their computer to a new location after the app is launched.

#### Estimated time: 10 minutes
## Exercise 1 - Configure and enable Continuous Access Evaluation
### Task 1 - Build your location based Conditional Access

1. Open a browser and connect to `http://entra.microsoft.com`.
2. From the **Identity** menu on the left, open the **Protection** portion of the menu.
3. Select **Conditional Access**.
4. Select **+ Create new policy** from the top of the screen.
5. Create a policy with the following values:

| Field | Value |
| :--- | :--- |
| Name | `Prevent launch based on location` |
| Assignments | Select **Adele Vance** |
| Target Resources | |
| | 1) Select **No target resources selected** |
| | 2) Choose **Select resources** |
| | 3) From the Select area, choose **None** |
| | 4) Mark **Office 365** and choose **Select** |
| Network | skip |
| Conditions | skip |
| Access controls | |
| | 1) From **Session** select **0 controls selected** |
| | 2) Mark **Customize continuous access evaluation** |
| | 3) Choose **Strictly enforce location policies (preview) |
| | 4) Use **Select** to confirm your choices |
| Enable policy | **Off** |

6. Select **Create**.

Within the lab testing environment, there is no good way to test this configuration option. Additionally, we have not configured Global Secure Access, so we are limited in to configuration options. But this simple policy demonstrates the process of selecting a specific application and adding restrictions that would prevent in from running from a specific location.  Even if the app was launched in one location and then then the PC was moved to a new location.  Conditional Access would catch the location change, and use CAE to expire the access token, blocking access to the app.

