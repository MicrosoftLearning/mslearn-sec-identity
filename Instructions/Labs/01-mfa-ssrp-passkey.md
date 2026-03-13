---
lab:
    title: 'Configure MFA and phishing resistant login with Passkeys'
    description: 'Configure multifactor authentication and phishing-resistant passkey sign-in in Microsoft Entra.'
    level: 300
    duration: 20
---

# Configure MFA and phishing resistant login with Passkeys

In this exercise you will configure Multifactor Authentication (MFA) registration, require MFA via Conditional Access, and enable phishing-resistant sign-in using Passkeys (FIDO2).

This exercise should take approximately **20** minutes to complete.

## Before you start

Before you can start this exercise, you will need to...

1. Sign in to `https://entra.microsoft.com` with an **Administrator** account.
1. Have the **Microsoft Authenticator** app installed on your mobile phone.
1. Have a Bluetooth-enabled mobile phone available — it is required for Passkey (FIDO2) setup in Lab 03.

## Task 1 - Enable Multifactor authentication registration

**Lab topics covered:**
- MFA Registration
- Microsoft Authenticator setup

#### Task scenario
Every company and every user should be protected by two-factor authentication.  With the rise of both phishing attacks and social engineering, it is crucial that you move away from a single password to protect your business.  This lab will show how to start your company on that process, without blocking access to any work systems.

1.	Launch the browser. Sign into `https://entra.microsoft.com` with a **Administrator** account.
2.	In the **Identity** menu on the left side of the screen open **Protection** then choose **Identity Protection**.
3.	Select **Multifactor authentication registration policy** from the newly opened screen.

   > **Note**: There is a pre-built **MFA registration policy** available.  It is configured to require All Users to complete the Microsoft Entra ID multifactor authentication registration process.  It is disabled by default.  You can modify the target audience to be a specific user or group for testing purposes.  You can choose to enable and disable as needed.  This policy does not require people to use MFA, just to configure themselves for MFA.  For the purposes of this lab, we are only doing to require one person to register.

4.	Select **All Users**, to open up the Include / Exclude dialog.
5.	On the Include tab, mark the **Select individuals and groups** item.
6.	Choose **Delia Dennis** from the list of users and groups that opens.

    > **Note**: You will need to create you Delia Dennis account for testing purposes.  Or you can use a different account.

7.	The use the **Select** button to finalize the choice.
8.	Select the **Exclude tab**.

   > **Note**: From the Exclude tab you could select specific users or groups that you don't want the policy to apply to.  Use this to protect certain accounts like Recovery or Break-Glass Accounts that you have set up for emergency purposes.  Those accounts should always be protected by using specific rules.

9. Select the **0 users and groups selected** item.
10. Mark the **Administrator** account you are using for the lab to exclude.
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
| | Get your domain from the resources tab. Example: DeliaD@<**your domain**> |
| Password | Use the supplied user password |

   > **Note**: If prompted to change your password, a **Pro Tip** is to grab one of the passwords from the **Resources tab**.  These passwords are always available and are secure, complex, and meet all login requirements.

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

    > **Note**: You will log in without needing MFA, although you did register for MFA in the previous task.

## Task 2 - Require MFA for connection to Cloud Admin sites

**Lab topics covered:**
- Enabling MFA
- Conditional Access MFA-Policy	

#### Task scenario

Your company is starting to launch a series of cloud applications that have access to customer data, and other important resources.  Users will need to connect to Microsoft Entra and Azure portals to get them set up.  You want to ensure that users connect using MFA secured account.

1. Sign into https://entra.microsoft.com with you **Administrator** account, if you are not already.
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
| | 4) Choose **Administrator** from the list of users |
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

### Subtask 1 - Log in as Delia Dennis to verify MFA requirement

1. Open a new InPrivate browser window.
2. Go to `https://www.office.com`.
3. Log in a **DeliaD** with the password created earlier.

- **Note** - Because you are going to a web site, you only needed your password, not MFA.

4. In the browser address bar, go to https://entra.microsoft.com to launch the **Entra admin center**.
5. Follow the on-screen instructions to confirm your MFA login with DeliaD.

--- 

## Task 3 - Enable Phishing resistant MFA for login

**Lab topics covered:**
- Phishing resistant MFA
- Authentication methods
- Authentication strengths
- Conditional Access	

#### Lab scenario

You have MFA registration completed and have started to require MFA for login.  However, you are hearing that your company's MFA protection could be even better.  You can strengthen your MFA requirements to make users log in with Phishing resistant MFA.

1. If not already logged in, connect to https://entra.microsoft.com with your **Administrator** account.
2. Select **Identity** then select **Protection** from the menu on the left.
3. From the Protection portion of the menu on the left choose **Authentication methods**.
3. Select **Policies** from the newly opened screen.
4. Select **Passkey (FIDO2)**.
5. Use the slider to **Enable** to Passkey (FIDO2) authentication method.
6. Select **Save**.

You have now made the phishing resistant option to use Passkeys available in your tenant.

### Subtask 1 - Use Authentication methods to create a Passkey (FIDO2) strong authentication

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

### Subtask 2 - Add Authentication strength to your Conditional Access policy

1. Open the **Protection** portion of the menu, then choose **Conditional Access**.
2. Select **Policies** from the screen that opens.
3. Choose the **Require MFA for portals** policy we created earlier.
4. Under **Access controls** in the Grant section select the **1 control selected** item.
4. **Unmark** the **Require multifactor authentication**.
5. **Mark** the **Require authentication strength**.
6. Use the dropdown to select the **Ignite Phishing resistant MFA** strength you created in the previous task.

    > **Note**: If the new authentication strength does not show up in the dropdown. Go to the upper-right corner and sign-out of the admin portal. Then close your browser, wait a minute. Then you can open the browser, and connect to `https://entra.microsoft.com` and log in as Administrator.  Start at Subtask 2 again.  It takes a few minutes for the new authentication strength to show up.

7. Use the **Select** button to exit the screen.
8. Ensure the **Enable policy** is set to **On**.
9. Select **Save**.

At this point, you have set up a policy using Conditional Access to require users to configure and log in with a Passkey, which is a phishing resistant login MFA method.  Reminder that we custom built the Authentication strength, so you could pick exactly what security options to want to use.  You could use the built in phishing resistant strength.

### Subtask 3 - Configure a passkey for Delia's log in - Passkey (FIDO2)

   > **Important**: Creating a passkey on the Microsoft Authenticator app requires a Bluetooth connection between your phone and computer.  Virtual machines do not support a Bluetooth connection.  So, perform the next few steps on the browser on you lab PC; not within the lab environment. 

1. Open an **InPrivate** browsing window.
2. Connect to `http://portal.azure.com`.
3. Log in as **DeliaD**.

- **Note** - you will be prompted for username and password we used previously in the lab.

4.	Select **Next** when the screen that says **your company needs more information** comes up.
5.	You should be prompted to **log in with MFA** to securely confirm your identity.
6.	Select **Yes** on the **Stay signed** in screen.

- **Note** - You will be prompted to build out your Passkey.

7.	Select **Next** on the **Create your passkey in Microsoft Authenticator** screen.

    > **Note**: Many Microsoft Authentication apps are not enabled to CREATE a Passkey.  To be safe we are going to use the Bluetooth method. When the **Complete the setup in Microsoft Authenticator** dialog appears, we will select "Having trouble?".

8. Select **Having trouble?**.
9. On the Having trouble screen, select **create your passkey a different way** text.
10.	Choose **iPhone** (or Android) from the list.
11.	Follow the steps on the **Turn on Microsoft Authenticator as passkey provider** that appear on your screen. 
12.	Select **Continue** when you are done.
13.	**Read** the **Get your devices ready** screen.

    > **Note**: At this point the setup will use Bluetooth to set up a secure connection between your PC and your phone.  This allows for a secure confirmation, transfer, and storage of you new Passkey.

14.	Select **I'm ready** to proceed.
15.	Make sure your **Phone type** is highlighted, then select **Next**.
16.	Open your **phone camera** and **scan the QR-code**.

    > **Note**: This will set up the secure Bluetooth link between your computer and phone.

17.	In the camera screen, choose **Save a Passkey** on your phone.
18.	Then select **Continue** on your phone.
19.	You will be prompted to enter for Microsoft Authenticator app passcode.
20.	On your PC, select **OK**.
21.	On the **Name your passkey** screen, select **Next**.

    > **Note**: In this lab environment, the name your passkey screen will sometimes hang.  This should not happen in a live environment.  If you get a spinning wait symbol for a minute; you can close your browser window.  You have completed the creation and save process for the Passkey.

22.	**Close the camera** on your phone.
23. **Close your InPrivate browser** on your PC.

You have now successfully created and saved your Passkey on the phone.

### Subtask 4 - Log in with Phishing resistant MFA - Passkey (FIDO2)

   > **Note**: Bluetooth is required for the login to work; please continue to use a browser outside of your lab environment on the PC.

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
