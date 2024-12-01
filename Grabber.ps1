# Powershell Script to automate getting logs for reporting on weekly meeting
# Written by ----=====|ePiRoC_nIcK|=====----

# Surface Data Location
$Surface_Manager_data_loc = "D:\ServerDataRoot_Backup\"

# Where the log file will save
$time_Stamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
$script_loc = Get-Location

$machines = @{
    'DR3132' = "8992013064"
    'DR3145' = "8992014939"
}

$start_date = Read-Host "Enter a Start Date"
$end_date = Read-Host "Enter a End date"

$start_date = Get-Date $start_date
$end_date = Get-Date $end_date 

Write-Host "starting $($start_date) and finishing $($end_date)"

# Example file Path
# 
# D:\ServerDataRoot_Backup\8992013064\From Machine\prodout\QUALLOG\2024-10\08
#
foreach ($machine in $machines.Keys){
    Write-Output "$($machine) has the serial number $($machines[$machine])"
}

$current_date = $start_date

Write-Host "Getting Machine Logs Now"


$Archive_save_path = "$($script_loc)\DR3132_RRA_LOGS_$($time_Stamp).zip"
while($current_date -le $end_date){
    try {
        $year = Get-Date $current_date -Format yyyy
        $month = Get-Date $current_date -Format MM
        $day = Get-Date $current_date -Format dd
        $data_path = "$($Surface_Manager_data_loc)$($machines[$machine])\From Machine\prodout\RIGEVENT\$($year)-$($month)\$($day)"
        Get-ChildItem -Path $data_path -ErrorAction Stop | Compress-Archive -update -DestinationPath $Archive_save_path
        Write-Host "Found Logs $($machines[$machine]) on $($month)"
        Write-Host $data_path
    } catch [System.Management.Automation.ItemNotFoundException]{
        Write-Host "Exception caught - No path"
        }
    
    
    $current_date = $current_date.AddDays(1)
}