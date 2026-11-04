# PowerShell remote administration

DC01 manages CLIENT01 through PowerShell remoting over WinRM using the domain administrator's identity. Remote commands execute independently of the desktop user's session.

## WinRM configuration

Local WinRM configuration requires elevated Windows PowerShell on CLIENT01:

```powershell
Enable-PSRemoting -Force
```

This configures the WinRM service, PowerShell session endpoints, and firewall rules.

## Connection and identity verification

Connection and execution checks from an administrative PowerShell session on DC01:

```powershell
Test-WSMan -ComputerName 'CLIENT01.corp.test'

Invoke-Command -ComputerName 'CLIENT01.corp.test' -ScriptBlock {
    hostname

    whoami
}
```

The remote commands returned `CLIENT01` and `corp\administrator`.

## Interactive sessions

```powershell
Enter-PSSession -ComputerName 'CLIENT01'

hostname

Get-Service -Name 'Spooler'

Exit-PSSession
```

Commands between `Enter-PSSession` and `Exit-PSSession` execute on CLIENT01.

## Remote service control

The service-control test used Print Spooler on CLIENT01. Printing was unavailable while the service was stopped.

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Stop-Service -Name 'Spooler' -ErrorAction Stop

    Get-Service -Name 'Spooler'
}
```

Service restoration:

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Start-Service -Name 'Spooler' -ErrorAction Stop

    Get-Service -Name 'Spooler'
}
```

The service was verified as Running, Stopped, then Running again.

## Event log query

```powershell
Invoke-Command -ComputerName 'CLIENT01' -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName      = 'System'
        ProviderName = 'Service Control Manager'
    } -MaxEvents 5 |
        Format-List TimeCreated, Id, Message
}
```

Event 7040 recorded WinRM changing from manual to automatic startup.
