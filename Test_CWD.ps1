# test script to see if get-location returns the path from where the scrit is run from.

Write-Host "Hello, Just testing Things"
Write-Host "Current working directory"


$my_loc = Get-Location


Write-Host "my current dir is: $($my_loc)"