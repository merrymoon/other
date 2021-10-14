# Local System Information v3
# Shows details of currently running PC
# Thom McKiernan 11/09/2014

$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerBIOS = Get-CimInstance CIM_BIOSElement
$computerOS = Get-CimInstance CIM_OperatingSystem
$computerCPU = Get-CimInstance CIM_Processor
#$computerHDD = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'"

#系统安装日期
$OSInstallTime=([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate)

#物理磁盘信息
$phsicalDisks=($info_diskdrive_basic = Get-WmiObject Win32_DiskDrive | 
ForEach-Object {
  $disk       = $_
  $partitions = "ASSOCIATORS OF " + 
                  "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " + 
                  "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
  Get-WmiObject -Query $partitions | 
  ForEach-Object {
    $partition = $_
    $drives    = "ASSOCIATORS OF " + 
                "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " + 
                "WHERE AssocClass = Win32_LogicalDiskToPartition"
    Get-WmiObject -Query $drives | 
    ForEach-Object {
      [PSCustomObject][Ordered]@{
        Disk          = "$($disk.DeviceID)"
        DiskModel     = "$($disk.Model)"
        Partition     = "$($partition.Name)"
        RawSize       = "$('{0:d} GB' -f [int]($partition.Size/1GB))"
        DriveLetter   = "$($_.DeviceID)"
        VolumeName    = "$($_.VolumeName)"
        Size          = "$('{0:d} GB' -f [int]($_.Size/1GB))"
        FreeSpace     = "$('{0:d} GB' -f [int]($_.FreeSpace/1GB))"
      }
    }
  }
})


#显示器信息

$Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID"  -ErrorAction SilentlyContinue

#Creates an empty array to hold the data
$Monitor_Array = @()


#Takes each monitor object found and runs the following code:
ForEach ($Monitor in $Monitors) {

  #Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
 If ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
    $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
  } else {
    $Mon_Model = $null
  }
  $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
  $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
  $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")


  #Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
  $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
  If ($Mon_Manufacturer_Friendly -eq $null) {
    $Mon_Manufacturer_Friendly = $Mon_Manufacturer
  }

  #Creates a custom monitor object and fills it with 4 NoteProperty members and the respective data
  $Monitor_Obj = [PSCustomObject]@{
    Manufacturer     = $Mon_Manufacturer_Friendly
    Model            = $Mon_Model
    SerialNumber     = $Mon_Serial_Number
    #AttachedComputer = $Mon_Attached_Computer
  }

  #Appends the object to the array
  $Monitor_Array += $Monitor_Obj

} #End ForEach Monitor

#Outputs the Array
$Monitor_Array


Clear-Host

Write-Host "System Information for: " $computerSystem.Name -BackgroundColor DarkCyan
"Manufacturer: " + $computerSystem.Manufacturer
"Model: " + $computerSystem.Model
"Serial Number: " + $computerBIOS.SerialNumber
"CPU: " + $computerCPU.Name
#"HDD Capacity: "  + "{0:N2}" -f ($computerHDD.Size/1GB) + "GB"
#"HDD Space: " + "{0:P2}" -f ($computerHDD.FreeSpace/$computerHDD.Size) + " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace/1GB) + "GB)"
"RAM: " + "{0:N2}" -f ($computerSystem.TotalPhysicalMemory/1GB) + "GB"
"Operating System: " + $computerOS.caption + ", Service Pack: " + $computerOS.ServicePackMajorVersion
"User logged In: " + $computerSystem.UserName
"Last Reboot: " + $computerOS.LastBootUpTime
"Last Reboot: " + $computerOS.LastBootUpTime

$phsicalDisks
#  powershell.exe -executionpolicy bypass  -file "c:\test\getinfo.ps1" -windowstyle hidden -noninteractive -nologo