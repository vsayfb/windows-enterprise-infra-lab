# Engineering user policy

`Engineering-User-Policy` is linked to `OU=Engineering,DC=corp,DC=test`. User settings apply according to the user account's OU location and GPO filtering, rather than membership in `GG_Engineering`.

## GPO definition and link

GPO creation and linking commands, executed in elevated Windows PowerShell on DC01:

```powershell
New-GPO -Name 'Engineering-User-Policy'

New-GPLink `
    -Name 'Engineering-User-Policy' `
    -Target 'OU=Engineering,DC=corp,DC=test'
```

## Policy configuration

Administrative Template configuration in `Engineering-User-Policy`:

| Property | Value |
|---|---|
| Policy path | User Configuration → Policies → Administrative Templates → Control Panel |
| Setting | Prohibit access to Control Panel and PC settings |
| Test state | Enabled |
| Final state | Not Configured |

## Policy application

User policy refresh and reporting were performed in Ali's non-elevated session on CLIENT01:

```powershell
gpupdate /target:user /force

gpresult /scope user /r
```

`Engineering-User-Policy` appeared under **Applied Group Policy Objects**. Settings and Control Panel access was blocked.

## Final configuration

The setting was returned to **Not Configured**. After `gpupdate /target:user /force`, Settings and Control Panel opened successfully. The GPO and OU link remain configured.

## Validation

| Check | Result |
|---|---|
| Settings and Control Panel with restriction enabled | Blocked for Ali |
| `gpresult` in Ali's session | `Engineering-User-Policy` listed as applied |
| Settings and Control Panel after reverting and refreshing policy | Opened successfully |

This policy restricts access to the interfaces. It does not replace account privileges or resource permissions.
