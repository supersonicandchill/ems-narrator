# EMS Narrator — Xcode Setup Guide
**App:** EMS Narrator  
**Bundle ID:** com.supersonicandchill.emsnarrator  
**Version:** 1.0.0  
**Product ID (StoreKit):** com.supersonicandchill.emsnarrator.monthly

---

## Step 1 — Folder Setup

Create a folder on your Mac called `ems-narrator`. Put these files in it:
- `ems_narrator_ios.html`
- `capacitor.config.json`
- `package.json`

Then create a subfolder called `www` and copy `ems_narrator_ios.html` into it, renamed to `index.html`.

---

## Step 2 — Install Dependencies

Open Terminal, navigate to your `ems-narrator` folder:

```bash
cd ~/Desktop/ems-narrator
npm install
npx cap add ios
npx cap sync
npx cap open ios
```

This opens the project in Xcode automatically.

---

## Step 2.5 — Add StoreKit Plugin

After `npx cap open ios` opens Xcode:

1. In Xcode file navigator, go to: **ios/App/App/Plugins**
2. Right-click → **New File** → **Swift File** → name it `StoreKitPlugin.swift`
3. Copy the entire contents of the `StoreKitPlugin.swift` file from your project folder
4. Right-click again → **New File** → **Objective-C File** → name it `StoreKitPlugin.m` (Xcode will ask to create a bridging header — click **Create**)
5. Copy the entire contents of `StoreKitPlugin.m` from your project folder into it. **This file is required** — without it, Capacitor never exposes the plugin to JavaScript at all.
4. Paste into the new file in Xcode
5. In the File Inspector (right panel), under **Target Membership**, check the box next to **App**
6. Press **Cmd+B** to build — it should compile without errors

This bridges your JavaScript purchase calls to Apple's StoreKit.

---

## Step 3 — Xcode Project Settings

In Xcode:
1. Click the top-level project in the left sidebar
2. Under **Signing & Capabilities** → set Team to your Apple Developer account
3. Bundle Identifier: `com.supersonicandchill.emsnarrator`
4. Version: `1.0.0`, Build: `1`
5. Deployment Target: **iOS 15.0+**

---

## Step 4 — App Store Privacy Policy

The privacy policy ships in this repo as `privacy.html` and is served by GitHub Pages once the site is deployed (see the deploy commands). Use this URL in App Store Connect:

`https://supersonicandchill.github.io/ems-narrator/privacy.html`

In App Store Connect: your app -> **App Information** -> **Privacy Policy URL** -> paste the URL -> Save.

Open the URL in a browser first and confirm it loads before submitting.

---

## Step 4B — In-App Subscriptions & StoreKit Configuration

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Create a new App → Bundle ID: `com.supersonicandchill.emsnarrator`
3. Under **In-App Purchases → Subscriptions**:
   - Create a new Subscription Group: `EMS Narrator Pro`
   - Add product:
     - **Product ID:** `com.supersonicandchill.emsnarrator.monthly`
     - **Price:** $2.99/month
     - **Free Trial:** None — free tier is handled inside the app (3 free narratives/month), not via Apple's introductory offer
     - **Display Name:** EMS Narrator Pro
     - **Description:** Full access to EMS Narrator — AI narrative polishing, custom protocols, unlimited logging.

---

## Step 5 — StoreKit Configuration File (for Local Testing)

Before submitting to App Store, you'll test purchases locally using a StoreKit Configuration File.

In Xcode:
1. File → New → File → **StoreKit Configuration File**
2. Name: `Products.storekit`
3. Click **Create**
4. Click **+ Add** → **Subscription**
5. Fill in:
   - **Reference Name:** EMS Narrator Pro Monthly
   - **Product ID:** `com.supersonicandchill.emsnarrator.monthly`
   - **Price:** $2.99 (select your region)
   - **Subscription Group:** Create new → name it `EMS Narrator Pro`
   - **Billing Period:** Monthly
   - No introductory offer needed — the free tier (3 narratives/month) is enforced in-app via localStorage, not through Apple's trial system
6. Save the file
7. Edit your Scheme: **Product → Scheme → Edit Scheme**
8. Go to **Run** tab → **Options** → **StoreKit Configuration** → select `Products.storekit`
9. Now when you run the app in the simulator, it uses this test configuration

---

## Step 6 — Signing & Capabilities

**Name:** EMS Narrator  
**Subtitle:** Paramedic Call Documentation  
**Category:** Medical  

**Description:**
EMS Narrator helps paramedics and EMTs document patient care narratives faster and more accurately — right from the field.

Tap your interventions, medications, and findings in the order they happen. EMS Narrator builds a chronological narrative automatically, then polishes it with AI into clean, professional documentation.

**Features:**
• Tap-to-log event timeline with timestamps
• GMVEMSC protocol built in — fully customizable
• AI narrative polishing (Claude & ChatGPT compatible)
• Successful/Unsuccessful outcome tracking per intervention
• Editable medications, interventions, and findings
• Custom medic unit management
• One-tap copy for your ePCR

**⚠ Important:** Always proofread your narrative. This tool assists documentation — it does not replace your clinical judgment. You are solely responsible for the accuracy of your patient care report.

**Questions or issues?** Contact us at supersonicandchill@gmail.com before leaving a review. We respond fast and want to make it right.

3 free narratives every month. Upgrade to EMS Narrator Pro for $2.99/month for unlimited narratives. Cancel anytime in iPhone Settings → Subscriptions.

---

## Step 6 — Signing & Capabilities

In Xcode:
1. Click the top-level **App** project in the left sidebar
2. Select the **App** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** → add **In-App Purchase**
5. Make sure your **Team** is set to your Apple Developer account
6. Press **Cmd+B** to build

---

## Step 7 — Privacy Policy URL (Required by Apple)

Already handled: `privacy.html` at the repo root is the policy, and it is live at
`https://supersonicandchill.github.io/ems-narrator/privacy.html` after deploy.
Paste that URL into App Store Connect (Step 4). If you change app behavior
(storage, network calls, analytics), update `privacy.html` to match before shipping.

---

## Step 8 — Submit to App Store

1. In Xcode: Product → Archive
2. Upload to App Store Connect via Organizer
3. Fill in screenshots (iPhone 15 Pro Max + iPhone SE minimum)
4. Submit for Review

**Review time:** typically 1–3 business days for medical apps.

---

## Developer Contact
supersonicandchill@gmail.com  
Buy Me a Coffee: https://buymeacoffee.com/dannycan
