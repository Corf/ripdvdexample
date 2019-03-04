function get-SMSTelestraAuth {
    param (
    [String]$app_key = "gobbldygook",
    [String]$app_secret = "gobbldygook2"
    )
   $headers  = @{
  'Content-Type' = 'application/x-www-form-urlencoded' 
  'cache-control' = 'no-cache'
  }
    $auth_Toke_String = "https://tapi.telstra.com/v2/oauth/token"
    $body = @{
    client_id= $app_key
    client_secret= $app_secret
    grant_type = "client_credentials"
    scope= "NSMS"
    }
    $auth_values = Invoke-WebRequest  $auth_Toke_String -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
    return $auth_values
}

function send-SMSTelstra {
    Param(
        [String]$phoneNo,
        [String]$message,
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject]$Auth
    )
    $SMS_String = " https://tapi.telstra.com/v2/messages/sms"
$body = @{
to = "$phoneNo"
validity ="60"
priority = $false
body = "$message"
}
    $body = $body | ConvertTo-Json
    $headers = @{
    Authorization = "Bearer $(($Auth.Content | ConvertFrom-Json).access_token)"
    Accept =  "application/json"
    'cache-control' = 'no-cache'
    'Content-Type' = 'application/json'
    }
    $SMSResults = Invoke-WebRequest $SMS_String -Body $body -Headers $headers -Method Post
 return $SMSResults
}


function get-DVD {
    param( [int]$DriveNo)
    
    while ($true)
    {
    
        sleep -Seconds 5
    
        sl "C:\Program Files (x86)\MakeMKv"

    
        $Diskmaster = New-Object -ComObject IMAPI2.MsftDiscMaster2 
        $DiskRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2 
        $diskRecExp  = '$DiskRecorder.InitializeDiscRecorder($DiskMaster[' + $DriveNo + '])'
        Invoke-Expression $diskRecExp
        $Driveletter =  $DiskRecorder.VolumePathNames[0]
        $Driveinfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 2 or DriveType = 5" -errorvariable MyErr -erroraction Stop | ?{$_.DeviceID -eq $($Driveletter -replace "\\")}

        if ($Driveinfo.VolumeName )
        {
            "Disk drive: $DriveNo`r`n$($Driveinfo.VolumeName)" > "D:\Video\$DriveNo.txt"
            $CommandTxt = '-noexit -command "while ($true){cls; GC D:\Video\DriveNo.txt; sleep -Seconds 2}"' -replace "DriveNo",$DriveNo
            if ($proc){$proc | Stop-Process}
            $proc = Start-Process -FilePath powershell -ArgumentList "$CommandTxt" -PassThru
            #$DiskRecorder.InitializeDiscRecorder($DiskMaster[$DriveNo]) 
            #if ($Eject) { 
            #    $DiskRecorder.EjectMedia() 
            #} elseif($Close) { 
            #    $DiskRecorder.CloseTray()
            #} 
            $Driveinfo.VolumeName


            $DVD = .\makemkvcon64.exe -r --cache=1 info disc:9999 | ConvertFrom-Csv | ?{$_.'MakeMKV v1.14.2 win(x64-release)' -eq $Driveinfo.VolumeName }

            $Drive =  $($DVD."MSG:1005" -replace "DRV:")

            $Folder =  $DVD.'MakeMKV v1.14.2 win(x64-release)'
            ### Folder check ###

            $FileandFolders  = ls D:\ -Recurse -File
            foreach ($item in $FileandFolders)
            {
                $namesplit = $item.name -split "\."
                if (($namesplit| select -First 1) -eq $folder)
                {
                    if ($item.PSIsContainer)
                    {
                        $item | Rename-Item -NewName $($item.name + "A") -ErrorAction SilentlyContinue
                    }Else{
                        $item | Rename-Item -NewName $($item.name + "A" + ".mkv") -ErrorAction SilentlyContinue
                    }
                }

            }






            #--noscan 
            #$expresion = ".\makemkvcon.exe backup --decrypt --cache=16 -r --progress=-same disc:$drive D:\Video\$Folder"
            mkdir "D:\Video\$Folder" -ErrorAction SilentlyContinue

            $expresion  =  ".\makemkvcon mkv disc:$Drive all 'D:\Video\$Folder'"
            Invoke-Expression $expresion >> "D:\Video\$DriveNo.txt"
            if ((gc "D:\Video\$DriveNo.txt") -notmatch "error|fail")
            {
                $log
                $DiskRecorder.EjectMedia()
                "Done" >> "D:\Video\$DriveNo.txt"
                
                $auth =  get-SMSTelestraAuth 
                $messageresult = send-SMSTelstra -phoneNo "0437099161" -message "$DriveNo ok" -Auth $auth 


                cls
            }Else{
                $auth =  get-SMSTelestraAuth 
                $messageresult = send-SMSTelstra -phoneNo "0437099161" -message "$DriveNo error" -Auth $auth 
            }

        }


    }
}