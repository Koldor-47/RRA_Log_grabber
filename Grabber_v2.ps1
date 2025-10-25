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
# This SCript uses .net libraries to perform the compression because that seem the best way
# To Keep the file structure inside the zip file, Compress-Archive was a bit complicated to get to work
#


# .Net Library include
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.Collections
    Write-Debug "Load .net library"
}
catch {
    Write-Debug "Opps .net Library not loaded"
} 


# Surface Data Location
$Surface_Manager_data_loc = "C:\Users\aucnh\Desktop\temp_logs\RRA"
$Surface_Manager_err_loc = "D:\ServerDataRoot_Error"

# Where the log file will save
$script_loc = Get-Location

$machines = @{
    'DR3132' = "8992013064"
    #'DR3145' = "8992014939"
    #'DR3149' = "8992015363"
    #'DR3151' = "8992015365"
    'DR2137' = "8999005050"
    '#DR3150' = "8992015369"
    'DR3152' = "8992015371"
    #'DR3123' = "8992012689"
    #'DR3124' = "8992012858"
}

$log_types = @('MWDLOG', 'PERFLOG', 'QUALLOG', 'RIGEVENT', 'STATLOG')


function Get-dataFiles {
    param(
        [string]$base_file_path,
        [DateTime]$start_date,
        [DateTime]$end_date
    )

    Write-Host "Starting date range $($start_date.ToString('dd-MM-yyyy')) to $($end_date.ToString('dd-MM-yyyy'))" -ForegroundColor 'Red'

    # Building a date range
    Write-Host "Calulating total days....."
    $date_range = [System.Collections.Generic.List[DateTime]]::new()
    $log_files = [System.Collections.Generic.List[string]]::new()
    $temp_date = $start_date
    while ($temp_date -le $end_date) {
        $date_range.Add($temp_date)
        $temp_date = $temp_date.AddDays(1)
    }

    foreach ($log in $log_types) {
        foreach ($drill in $machines.Keys) {
            foreach ($date in $date_range) {
                $year = $date.ToString('yyyy')
                $month = $date.ToString('MM')
                $day = $date.ToString('dd')
                
                $data_path = Join-Path $base_file_path "$($machines[$drill])\From Machine\prodout\$log\$year-$month\$day"
                $data_files = Get-ChildItem -Path $data_path -File -ErrorAction SilentlyContinue

                foreach ($file in $data_files) {
                    $full_path = $file.FullName
                    $log_files += $full_path
                }

            }
        }
    }
    
    return $log_files
}

function Get-logArchive {
    param(
        [string]$base_path,
        [array]$files,
        [DateTime]$start_date,
        [DateTime]$end_date
    )

    if ($files.Count -eq 0) {
        Write-Host "No Files Found" -ForegroundColor 'Red'
        return
        }
    
    $Archive_name = "RRA_logs_$($start_date.ToString('dd-MM-yyyy'))_to_$($end_date.ToString('dd-MM-yyyy')).zip"
    $full_Archive_name = Join-Path $script_loc $Archive_name
    $log_archive = [System.IO.Compression.ZipFile]::Open($full_Archive_name, [System.IO.Compression.ZipArchiveMode]::Create)
    $file_progress_count = 0
    try{
        foreach ($log_file in $files) {
            $relative_path = $log_file.Substring($base_path.Length + 1)

            $zip_entry_name = $relative_path.Replace('\', '/')

            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $log_archive,
                $log_file,
                $zip_entry_name,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
            Write-Progress -Activity "saving RRA logs" -PercentComplete (($file_progress_count / $files.Count) * 100)
            $file_progress_count++
        }
    }
    finally {
        $log_archive.Dispose()
    }
}

$heading_2 = @"
  _______    _______        __           ___        ______    _______       ________     __  ___      ___  _______   _______  
 /"      \  /"      \      /""\         |"  |      /    " \  /" _   "|     /"       )   /""\|"  \    /"  |/"     "| /"      \ 
|:        ||:        |    /    \        ||  |     // ____  \(: ( \___)    (:   \___/   /    \\   \  //  /(: ______)|:        |
|_____/   )|_____/   )   /' /\  \       |:  |    /  /    ) :)\/ \          \___  \    /' /\  \\\  \/. ./  \/    |  |_____/   )
 //      /  //      /   //  __'  \       \  |___(: (____/ // //  \ ___      __/  \\  //  __'  \\.    //   // ___)_  //      / 
|:  __   \ |:  __   \  /   /  \\  \     ( \_|:  \\        / (:   _(  _|    /" \   :)/   /  \\  \\\   /   (:      "||:  __   \ 
|__|  \___)|__|  \___)(___/    \___)     \_______)\"_____/   \_______)    (_______/(___/    \___)\__/     \_______)|__|  \___)                                                                     
             
"@

# Main Flow starts here.
Write-Host $heading_2
Write-host "Enter a Date YYYY-MM-DD"

$start_date = Read-Host "Enter a Start Date"
$end_date = Read-Host "Enter a End date"

$start_date = Get-Date $start_date
$end_date = Get-Date $end_date 

$testme = Get-dataFiles -base_file_path $Surface_Manager_data_loc -start_date $start_date -end_date $end_date

$time_taken = Measure-Command { Get-logArchive -base_path $Surface_Manager_data_loc -start_date $start_date -end_date $end_date -files $testme }

Write-Host "RRA Log saving Complete" -ForegroundColor 'Green'

Write-Host "Archiving took $($time_taken)"


