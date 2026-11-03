# PowerShell remote administration

DC01 manages CLIENT01 through PowerShell remoting over WinRM using the domain administrator's identity. Remote commands execute independently of the desktop user's session.

## Enable remoting

On CLIENT01, open Windows PowerShell as Administrator and run:

```powershell
Enable-PSRemoting -Force
```

This configures the WinRM service, PowerShell session endpoints, and firewall rules.

## Test connectivity and execution

Run from DC01 in an administrative PowerShell session:

```powershell
Test-WSMan -ComputerName 'CLIENT01.corp.test'

Invoke-Command -ComputerName 'CLIENT01.corp.test' -ScriptBlock {
    hostname

    whoami
}
```

The remote commands returned `CLIENT01` and `corp\administrator`.

## Use an interactive session

```powershell
Enter-PSSession -ComputerName 'CLIENT01'

hostname

Get-Service -Name 'Spooler'

Exit-PSSession
```

Commands between `Enter-PSSession` and `Exit-PSSession` execute on CLIENT01.

## Control a service remotely

Run from DC01. Stopping Print Spooler temporarily disables printing on CLIENT01.

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Stop-Service -Name 'Spooler' -ErrorAction Stop

    Get-Service -Name 'Spooler'
}
```

Restore the service:

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Start-Service -Name 'Spooler' -ErrorAction Stop

    Get-Service -Name 'Spooler'
}
```

The service was verified as Running, Stopped, then Running again.

## Inspect event logs

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName      = 'System'
        ProviderName = 'Service Control Manager'
    } -MaxEvents 5 |
        Format-List TimeCreated, Id, Message
}
```

Event 7040 recorded WinRM changing from manual to automatic startup. The selected query for event 7036 returned no matches; Spooler state changes were verified directly with `Get-Service`.
