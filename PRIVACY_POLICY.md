# Privacy Policy — Share Adi

**Last updated:** September 9, 2026

This Privacy Policy describes how Share Adi (the "App") collects, uses, and
protects your information when you use our expense-sharing app.

By using the App, you agree to the practices described in this policy.

---

## 1. Information We Collect

### Account information
- **Email address** and **display name** you provide when signing up or
  signing in.
- A **hashed password** in place of your password itself — we never store or
  have access to plaintext passwords.

### Group and transaction data
- **Groups** you create or join (name, type, join code).
- **Members** added to a group (name, and optionally email and UPI ID).
- **Expenses**: amounts, descriptions, dates, who paid, and how amounts were
  split among members.
- **Payments** recorded between members to settle balances (amount, date,
  note), including confirmation of receipts.

### Device and service data
- Your **device timezone** is read so that month-end settle-up reminders are
  scheduled at the correct local time. This value is used on-device.
- **Notification permission** is requested solely to deliver the optional
  month-end settle-up reminders you opt into.

## 2. How We Use Your Information

We use the information above to:

- Create and manage your account and authenticate you.
- Let you create, join, and manage groups.
- Record expenses, splits, payments, and balances so members can track and
  settle shared expenses.
- Send the scheduled month-end settle-up reminders you have enabled.
- Share statements and receipts (as PDFs) that you choose to export or share.
- Operate, secure, and improve the App.

We do **not** sell, rent, or trade your personal information. We do not display
advertising, and we do not use third-party analytics or tracking SDKs.

## 3. Sharing of Information

Information is shared only in the following limited ways:

- **Within your groups:** Other members of a group can see the expenses,
  splits, payments, and balances for that group, along with member names, UPI
  IDs, and the email addresses you choose to share. This is the core purpose of
  the App.
- **Service providers:** We use **Supabase** to host authentication, your
  account data, and group data. Supabase processes data on our behalf to
  provide the service (see
  [Supabase's privacy practices](https://supabase.com/privacy)).
- **Other apps you choose:** When you use WhatsApp, email, UPI payments, Google
  Pay, or the share sheet to share invites or make payments, the third-party app
  you select receives only the content you explicitly share or send.

## 4. Data Retention

We retain your data for as long as your account is active, so that your groups,
expenses, and balances remain available to you and the groups you belong to.
When you ask us to delete your account and data, we delete or anonymize your
data, subject to any legal obligations to retain it.

## 5. Security

- Data is transmitted over encrypted connections (HTTPS).
- Passwords are stored only as secure hashes by our authentication provider.
- Access to your data is limited to the groups you belong to, enforced by
  backend access rules.

No method of electronic storage or transmission is 100% secure. While we use
reasonable safeguards, we cannot guarantee absolute security.

## 6. Your Rights

Depending on your location (including under applicable laws such as the GDPR),
you may have the right to:

- **Access** the personal data we hold about you.
- **Correct** or **update** your information.
- **Delete** your account and associated data.
- **Object to** or **restrict** certain processing.
- **Withdraw consent** for optional features (such as notifications) at any
  time from your device settings.

To exercise any of these rights, contact us using the details below.

## 7. Children's Privacy

Share Adi is not directed at children under 13, and we do not knowingly collect
personal information from children under 13. If you believe a child has
provided us with personal information, contact us and we will delete it.

## 8. Changes to This Policy

We may update this policy from time to time. When we do, we will revise the
"Last updated" date above. If changes are significant, we will provide notice
in the App before they take effect. Continued use of the App after changes
means you accept the updated policy.

## 9. Contact Us

If you have questions or requests about this Privacy Policy or your data,
contact us at:

**Share Adi**
Email: `[your contact email]`

---

## Play Console note (for the developer)

Google Play requires a privacy policy URL on the store listing and a completed
**Data Safety** form. To publish this policy:

1. Host this file somewhere public (for example, a GitHub Pages site or a
   static site), and paste the URL into the Play Console listing.
2. In the Data Safety form, report what this policy describes, aligning with
   the App's actual data practices:
   - Personal info: Email address, Name (collected, used for app
     functionality; not shared), plus user-generated content (expenses,
     groups, etc.).
   - No ads, no analytics, no location collection, no device identifiers
     beyond what the OS provides.