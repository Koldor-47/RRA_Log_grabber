# Powershell Script to automate getting logs for reporting on weekly meeting
# 
# __          __   _ _   _               _           
# \ \        / /  (_) | | |             | |          
#  \ \  /\  / / __ _| |_| |_ ___ _ __   | |__  _   _ 
#   \ \/  \/ / '__| | __| __/ _ \ '_ \  | '_ \| | | |
#    \  /\  /| |  | | |_| ||  __/ | | | | |_) | |_| |
#     \/  \/ |_|  |_|\__|\__\___|_| |_| |_.__/ \__, |
#                                               __/ |
#  ______       _                  _   _ _     |___/ 
# |  ____|     (_)                | \ | (_)    | |   
# | |__   _ __  _ _ __ ___   ___  |  \| |_  ___| | __
# |  __| | '_ \| | '__/ _ \ / __| | . ` | |/ __| |/ /
# | |____| |_) | | | | (_) | (__  | |\  | | (__|   < 
# |______| .__/|_|_|  \___/ \___| |_| \_|_|\___|_|\_\
#        | |                                         
#        |_|                                         
#
#
#
# Surface Data Location
$Surface_Manager_data_loc = "D:\ServerDataRoot_Backup"
$Surface_Manager_err_loc = "D:\ServerDataRoot_Error"

# Where the log file will save
$time_Stamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
$script_loc = Get-Location

# Added Fortescue Normal Machines
#$machines = @{
#	'DR3124' = "8992012858"
#}

$machines = @{
    'DR3132' = "8992013064"
    'DR3145' = "8992014939"
    'DR3149' = "8992015363"
    'DR3151' = "8992015365"
    'DR2137' = "8999005050"
}



$log_types = @('MWDLOG', 'PERFLOG', 'QUALLOG', 'RIGEVENT', 'STATLOG')

Write-host "Enter a Date YYYY-MM-DD"

$start_date = Read-Host "Enter a Start Date"
$end_date = Read-Host "Enter a End date"

$start_date = Get-Date $start_date
$end_date = Get-Date $end_date 

Write-Host "starting $($start_date) and finishing $($end_date)"

foreach ($machine in $machines.Keys){
    Write-Output "$($machine) has the serial number $($machines[$machine])"
}

$current_date = $start_date

Write-Host "Getting Machine Logs Now"


function getDrillData {
    param([string]$drillDataPath,
	  [string]$DataLogType
	)

foreach ($drill in $machines.Keys) {
    
	if (!(Test-Path -Path "$($script_loc)\$($drill)" -PathType Container))
	{
		New-Item -Path "$($script_loc)\" -Name "$($drill)" -ItemType "directory"
	}
	
    foreach ($log_type in $log_types) {
        Write-Output "Log file: $($log_type) on machine: $($drill) $($machines[$drill])"
        $current_date = $start_date

        while($current_date -le $end_date){
            $Archive_save_path = "$($script_loc)\$($drill)\$($drill)Mahince_RRA_LOGS_$($DataLogType)_$($log_type)_$($machines[$drill])_$($time_Stamp).zip"
            try {
                $year = Get-Date $current_date -Format yyyy
                $month = Get-Date $current_date -Format MM
                $day = Get-Date $current_date -Format dd
              
                $data_path = "$($drillDataPath)\$($machines[$drill])\From Machine\prodout\$($log_type)\$($year)-$($month)\$($day)"
                
                Get-ChildItem -Path $data_path -ErrorAction Stop | Compress-Archive -update -DestinationPath $Archive_save_path
                Write-Host "Found Logs $($machines[$drill]) on $($month)"
                Write-Host $data_path
            } catch [System.Management.Automation.ItemNotFoundException]{
                Write-Host "Exception caught - No path"
                }
            
            
            $current_date = $current_date.AddDays(1)
            }
        }
    }
    }

    getDrillData "$Surface_Manager_data_loc" "good"
    Write-Host "Collecting Error Logs"
    getDrillData "$Surface_Manager_err_loc" "Error"

    Write-Host "Finished Collecting Logs"
