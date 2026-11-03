# Engineering user policy

`Engineering-User-Policy` is linked to `OU=Engineering,DC=corp,DC=test`. User settings apply according to the user account's OU location and GPO filtering, rather than membership in `GG_Engineering`.

## Create and link the GPO

Run in elevated Windows PowerShell on DC01:

```powershell
New-GPO -Name 'Engineering-User-Policy'

New-GPLink `
    -Name 'Engineering-User-Policy' `
    -Target 'OU=Engineering,DC=corp,DC=test'
```

## Configure the restriction

1. Open **Server Manager → Tools → Group Policy Management**.
2. Expand **Forest: corp.test → Domains → corp.test → Group Policy Objects**.
3. Right-click **Engineering-User-Policy** and select **Edit**.
4. Open **User Configuration → Policies → Administrative Templates → Control Panel**.
5. Set **Prohibit access to Control Panel and PC settings** to **Enabled**.

## Verify application

On CLIENT01, sign in as `CORP\ali` and run in a normal PowerShell session:

```powershell
gpupdate /target:user /force

gpresult /scope user /r
```

Inspect **Applied Group Policy Objects** for `Engineering-User-Policy`. Attempt to open Settings and Control Panel.

## Revert the restriction

Set the same policy to **Not Configured**, run `gpupdate /target:user /force` in Ali's session, and reopen Settings and Control Panel. The GPO and OU link remain in place.

## Validation

| Check | Result |
|---|---|
| Settings and Control Panel with restriction enabled | Blocked for Ali |
| `gpresult` in Ali's session | `Engineering-User-Policy` listed as applied |
| Settings and Control Panel after reverting and refreshing policy | Opened successfully |

This policy restricts access to the interfaces. It does not replace account privileges or resource permissions.
