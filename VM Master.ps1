#
# VM Creator script
#
# Made by: https://github.com/Lite-Project
#
# Version v0.1
#
# W.I.P
# [7] in VM creation is going to be VHD type eg; vhdxor vhd, dynamic or fixed
#

if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne "Enabled") {
$intrvm = Get-VMHost
$LP = $intrvm.LogicalProcessorCount
$RAM = [Math]::Round(($intrvm.MemoryCapacity/1Gb),1)
$global:vmpath = $intrvm.VirtualMachinePath
$global:VHDpath = $intrvm.VirtualHardDiskPath
$VHDMXFS = Get-Volume -DriveLetter (Get-Item $global:vmpath).PSDrive.Name #VHD Max File Size

$fl = $PSScriptRoot
$top = New-Object System.Windows.Forms.Form -Property @{
    TopMost = $true
    MinimizeBox = $true}

$iso = New-Object System.Windows.Forms.OpenFileDialog -Property @{
Title = "Please Select Iso File" 
InitialDirectory = [Environment]::GetFolderPath('Desktop') 
Filter = "iso files (*.iso)|*.iso|All files (*.*)|*.*"}
$dpath = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    SelectedPath = [Environment]::GetFolderPath('Desktop')
    Description = "Please Select a Folder"}

#Default VM Settings
$vms = @{
    Selector = ""
    Name = ""
    Gen = "2" # 1 or 2
    RAM = "2147483648" #1GB = 1073741824 2GB = 2147483648 4GB = 4294967296
    Switch = "Default Switch"
    VHDSize = "107374182400" #100GB
    Quantity = "1"
    BootMethod = "N/A"
}

function SCreate {
    param($v)
    $t = $null
    if ($v -eq $null) {[hashtable]$v = $vms}
    $v.Selector = ""
    if ($v.RAM -ge 1GB) {
        $tr = "$($v.RAM / 1GB)GB"
    } elseif($v.RAM -ge 1MB) {
        $tr = "$($v.RAM / 1MB)MB"
    }
    cls
    Write-Host @"
Default VM Settings
[1] Name: $($v.Name)
[2] Gen: $($v.Gen)
[3] RAM: $tr
[4] Switch: $($v.Switch)
[5] VHD Size: $($v.VHDSize / 1Gb) GB
[6] Method of Boot: $($v.BootMethod)
[7] W.I.P

[9] Confirm
$($v.Selector)
"@
    [string]$t = Read-Host " "
    if ($t -ne '') {
        if (1..8 -eq $t.Substring(0,1)) {
            $v.Selector = $t.Substring(0,1)
            $v = ErrCh -VMPrem $v
            SCreate
        }
        elseif (($t.Substring(0,1) -eq 9) -and ($v.name -ne '')) {
            $v.Selector = $t.Substring(0,1)
            ErrCh -VMPrem $v
            main
        }
        else {SCreate}
    } else {SCreate}
}

function MCreate {
    param($v)
    $t = $null
    if ($v -eq $null) {
        [hashtable]$v = $vms
    }
    $v.Selector = ""
    if ($v.RAM -ge 1GB) {
        $tr = "$($v.RAM / 1GB)GB"
    } elseif($v.RAM -ge 1MB) {
        $tr = "$($v.RAM / 1MB)MB"
    }
    $tn = "$($v.Name)"
    cls
    Write-Host @"
Default VM Settings
[1] Name: $($v.Name) eg; $($v.Name)00
[2] Gen: $($v.Gen)
[3] RAM: $tr
[4] Switch: $($v.Switch)
[5] VHD Size: $($v.VHDSize / 1Gb) GB
[6] Method of Boot: $($v.BootMethod)
[7] W.I.P
[8] Quantity: $($v.Quantity)

[9] Confirm
$($v.Selector)
"@
    [string]$t = Read-Host " "
    if ($t -ne '') {
        if (1..8 -eq $t.Substring(0,1)) {
            $v.Selector = $t.Substring(0,1)
            $v = ErrCh -VMPrem $v
            MCreate
        }
        elseif ((9 -eq $t.Substring(0,1)) -and ($($v.Name -ne ''))) {
            $v.Selector = $t.Substring(0,1)
            $n = $v.Name
            $p = 0
            For ($x=0; $x -le ([int]$($v.Quantity) - 1); $x++) {
                $p = $p + 1
                if ($p -le 9) {
                    $v.Name = "$($n)0$($p)"
                } else {$v.Name = "$($n)$($p)"}
                ErrCh -VMPrem $v
            }
            Write-Host "All $($v.Quantity) VM's Have been Created"
            Read-Host " "
            main
        } else {MCreate}
    }
    else {
        MCreate
    }
}

function RDP {
    cls
    $t = $null
    [string]$t = Read-Host "Please Enter the Name for the VM"
    if ($t -ne '') {
        if ((Get-VM | Select-Object -ExpandProperty Name) -contains $t) {
            VMConnect $env:COMPUTERNAME $t
            exit
        } else {
            Write-Error "No VM matches name."
            Read-Host " "
            RDP
        }
    } else {
        Write-Warning "Empty Names are invalid"
        Read-Host " "
        RDP
    }
}

function ErrCh {
    param(
        [hashtable]$VMPrem
    )
        if (1..8 -eq $($VMPrem.Selector)) {
            if (1 -eq $($VMPrem.Selector)) {
                $t = $null
                [string]$t = Read-Host "Please Enter the Name for the VM"
                $t = $t -replace '[^a-zA-Z0-9/ ]', ''
                if (!(($t.Length -eq 1) -and ( $t -eq " "))) {
                    if (!((Get-VM | Select-Object -ExpandProperty Name) -imatch $t)) {
                        $VMPrem.Name = $t
                        $VMPrem.Selector = 0
                        return $VMPrem
                    } else {
                        $VMPrem.Selector = 0
                        return $VMPrem
                    }
                } else {
                    Write-Warning "Single Space Names are invalid"
                    Read-Host " "
                    return $VMPrem
                }
            }
            elseif (2 -eq $($VMPrem.Selector)) {
                $t = $null
                while (!(($t -eq "1") -or ($t -eq "2"))) {
                    cls
                    $t = Read-Host "Which Generation? 1 or 2"
                    if (!(($t -eq "1") -or ($t -eq "2"))) {
                        Write-Warning "Please only choose 1 or 2"
                        Read-Host " "    
                    }
                }
                $VMPrem.Gen = $t
                $VMPrem.Selector = 0
                return $VMPrem
            }
            elseif (3 -eq $($VMPrem.Selector)) {
                $t = $null
                while (!(($t -imatch "GB") -or ($t -imatch "MB"))) {
                    cls
                    $t = Read-Host -Prompt "How much memory would you like to assign"
                    try {
                        $it = [int64]$t.Trim("GB").Trim("MB") * 1MB
                    } catch {
                        Write-Warning "Invalid Format eg; 4GB"
                        $t = $null
                        Read-Host " "
                    }
                    if ($t -imatch "GB") {
                        $it = [int64]$t.Trim("GB") * 1GB
                    }
                    elseif ($t -imatch "MB") {
                        $it = [int64]$t.Trim("MB") * 1MB
                    }
                    if (($it -lt 536870912) -or ($it -ge ($intrvm.MemoryCapacity - 4GB))) {
                        $t = $null
                        Write-Warning "Minimum is 512MB and Maximum is $([Math]::Round((($intrvm.MemoryCapacity - 4GB)/1GB),1))GB"
                        Read-Host " "
                    }
                    else {
                        $VMPrem.RAM = $it
                        $VMPrem.Selector = 0
                        return $VMPrem
                    }
                }
            }
            elseif (4 -eq $($VMPrem.Selector)) {
                cls
                $t = $null
                $ts = Get-VMSwitch | Select Number,Name,SwitchType
                [int]$i = 0
                
                $ts | ForEach-Object {
                    $ts[$i].Number = "[$($i + 1)]"
                    $i = $i + 1
                }
                Write-Host "Please Select which switch you would like to use"
                $ts = $ts | Format-Table | Out-String
                Write-Host $ts
                Write-Host "[$($i + 1)]    Create New"
                $t = Read-Host -Prompt " "
                if (($t -ge 1) -and ($t -le $i)) {
                    $ts = Get-VMSwitch | Select Name,SwitchType
                    $VMPrem.Switch = $ts.Name[$([int]$t - 1)]
                    $VMPrem.Selector = 0
                    return $VMPrem
                } elseif ($t -eq $($i + 1)) {
                    $a = $false
                    while ($true) {
                        if ($a -ne $true) {
                            $t = $null
                            $t = Read-Host "Name for Switch"
                            $t = $t -replace '[^a-zA-Z0-9/ ]', ''
                        }
                        if (!((Get-VMSwitch | Select-Object -ExpandProperty Name) -contains $t)) {
                            $a = $true
                            cls
                            Write-Host @"
Switch Name: $t
Switch Type: Internal, Private or External
"@
                            $st = Read-Host "What Type"
                            if (($st -ieq "Internal") -or ($st -ieq "Private") -or ($st -ieq "External")) {
                                New-VMSwitch -Name $t -SwitchType $st
                                $c = $true
                                $VMPrem.Switch = $t
                                $VMPrem.Selector = 0
                                Return $VMPrem
                            }
                            
                        } else {
                            Write-Warning "Switch Name Detected, please use a different name."
                            Read-Host " "
                        }
                    }
                }
            }
            elseif (5 -eq $($VMPrem.Selector)) {
                $t = $null
                while (!(($t -imatch "GB") -or ($t -imatch "MB"))) {
                    cls
                    $t = Read-Host -Prompt "How much Storage would you like to assign"
                    try {
                        $it = [int64]$t.Trim("GB").Trim("MB") * 1GB
                    } catch {
                        Write-Warning "Invalid Format eg; 100GB"
                        $t = $null
                        Read-Host " "
                    }
                    if ($t -imatch "GB") {
                        $it = [int64]$t.Trim("GB") * 1GB
                    }
                    elseif ($t -imatch "MB") {
                        $it = [int64]$t.Trim("MB") * 1MB
                    }
                    if ($it -lt 536870912) {
                        $t = $null
                        Write-Warning "Minimum is 512MB"
                        Read-Host " "
                    }
                    else {
                        if ($it -ge ($VHDMXFS.SizeRemaining - 10GB)) {
                            Write-Warning @"
Your storage space is almost full or already exceeding the limit you have.
Desired Storage: $t
Remaining Storage: $([Math]::Round(($VHDMXFS.SizeRemaining/1GB),1)) GB
Please Specify Dynamically Expanding
"@
                        }
                        Write-Warning @"
NOTE: 
CHANGING VHD TYPE HAS NOT BEEN ADDED YET
AUTOMATICALLY SET TO VHDX AND DYNAMICALLY EXPANDING
OLDER OS DOES NOT SUPPORT VHDX
"@
                        Read-Host " "
                        $VMPrem.VHDSize = $it
                        $VMPrem.Selector = 0
                        return $VMPrem
                    }
                }
            }
            elseif (6 -eq $($VMPrem.Selector)) {
                while ($true) {
                    cls
                    Write-Host "Boot Method"
                    $t = Read-Host "N/A or Iso"
                    if ($t.Substring(0,3) -eq "iso") {
                        $is = "TEMP"
                        while($true) {
                            if (!($is.Substring($is.Length - 3) -eq "iso")) {
                                $n = $iso.ShowDialog()
                                [string]$is = $iso.FileName
                                if ($is.length -lt 3) {
                                    $is = "TEMP"
                                }
                            }
                            if (($n -eq "OK") -and ($is.Substring($is.Length - 3) -eq "iso")) {
                                $VMPrem.BootMethod = $is
                                $VMPrem.Selector = 0
                                return $VMPrem
                            }
                            elseif ($n -eq "Cancel") {
                                $VMPrem.Selector = 0
                                return $VMPrem
                            }
                        }
                    } 
                    elseif ($t.Substring(0,3) -eq "N/A") {
                        $VMPrem.BootMethod = "N/A"
                        $VMPrem.Selector = 0
                        return $VMPrem
                    }
                }
            }
            elseif (7 -eq $($VMPrem.Selector)) {
                cls
                Write-Warning "W.I.P VHD TYPE"
                Read-Host " "
                return $VMPrem
            }
            elseif (8 -eq $($VMPrem.Selector)) {
                Write-Host "How many VM's do you want?"
                $t = Read-Host " "
                $ti = $t -as [int]
                if (($ti -is [int]) -and ($ti -ge 1) -and ($ti -le 99)) {
                    $VMPrem.Quantity = $t
                    return $VMPrem
                }
                elseif (($ti -is [int]) -and ($ti -ge 99)) {
                    Write-Warning "Max creation is 99"
                    Read-Host " "
                    return $VMPrem
                } else {
                    Write-Host "SKIPPED"
                    Read-Host
                    return $VMPrem
                }
            }
        }
        elseif (9 -eq $($VMPrem.Selector)) {
            if ($VMPrem.Name -ne $null) {
                Write-Host "Creating VM."
                New-VM -Name $($VMPrem.Name) `
                    -Generation $($VMPrem.Gen) `                    -MemoryStartupBytes $($VMPrem.RAM) `                    -NewVHDPath "$global:VHDpath\$($VMPrem.Name).vhdx" `                    -NewVHDSizeBytes $($VMPrem.VHDSize) `
                    -SwitchName $($VMPrem.Switch)

                if ($VMPrem.BootMethod -match ".iso") {
                    Add-VMDvdDrive -VMName $VMPrem.Name -Path $VMPrem.BootMethod
                    Set-VMFirmware $VMPrem.Name -BootOrder (Get-VMDvdDrive -VMName $VMPrem.Name),(Get-VMHardDiskDrive -VMName $VMPrem.Name -ControllerLocation 0),(Get-VMNetworkAdapter -VMName $VMPrem.Name)
                    Write-Host "Assigned Iso successfully."
                    Read-Host " "
                    return
                } elseif ($VMPrem.BootMethod -eq "N/A") {
                    Write-Host "Assigning default boot method."
                    return
                } else {
                    Write-Error "VM BOOT METHOD FAILURE $($VMPrem.BootMethod)"
                    break
                }
            }
        }
        else {
            Write-Error "ERROR CHECK FUNCTION EXECUTION ERROR"
            Write-Host $VMPrem
            Read-Host -Prompt " "
        }
}

function default {
    cls 
    Write-Host @"
Which Default Parameter would you like to change?


[1] VM Folder Location
[2] VHD Folder Location
"@
    [string]$t = Read-Host " "
    if ($t -ne '') {
        if ($t.Substring(0,1) -eq 1) {
            $n = $dpath.ShowDialog($top)
            if ($n -eq "OK") {
                $global:vmpath = $dpath.SelectedPath
                main
            } else {default}
        }
        elseif ($t.Substring(0,1) -eq 2) {
            $n = $dpath.ShowDialog($top)
            if ($n -eq "OK") {
                $global:vmpath = $dpath.SelectedPath
                main
            } else {default}
        } else {
            Write-Warning "Please only enter 1 or 2"
            Read-Host " "
        }
    } else {default}
}

function main {
    cls
    Write-Host "                    " -NoNewline
    Write-Host -ForegroundColor white -BackgroundColor black "Virtual Machine Creator"
    Write-Host -ForegroundColor cyan @"
    

               Total Logical Processors: $LP
    
               Total Ram Size: $RAM Gb
               
               Virtual Machine Path: $global:vmpath
               Virtual Disk Path: $global:VHDpath
               Total Free Space in Disk path: $([Math]::Round(($VHDMXFS.SizeRemaining/1GB),1)) Gb from $([Math]::Round(($VHDMXFS.Size/1GB),1)) Gb

               
"@
    Write-Host -ForegroundColor white @'


[1] Single Creation
[2] Multi Creation
[3] Connect to VM
[4] Change Default VM Settings 
'@ -NoNewline
    Write-Host -ForegroundColor Red -BackgroundColor Black ' - IMPORTANT - '
    Write-Host -ForegroundColor Gray @'
 
Press 9 to exit
'@ -NoNewline
    $ui = Read-Host " "
    if ($ui -ieq '1') {
        SCreate $vms
    }
    elseif ($ui -ieq '2') {
        MCreate $vms
    }
    elseif ($ui -ieq '3') {
        RDP
    }
    elseif ($ui -ieq '4') {
        default
    }
    elseif ($ui -ieq 9) {
        exit
    }
    else {
        main
    }
}
main
} else {
    Write-Warning "Hyper-V needs to be installed."
}