While ($true)
{

    $VolumeNames = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 2 or DriveType = 5").VolumeName 

    $matchArrary =@()
    $VolumeNames | %{if ($_.count -gt 0){$matchArrary += $_}}
    (ls D:\264 -Recurse).Name | %{$_ -replace '\.mkv'} | %{$matchArrary += $_}
    if ($matchArrary)
    {

    $NotMatch  =  $matchArrary -join "|"
    $folders  = ls D:\Video -Directory -Recurse | ?{$_.name -notmatch "$NotMatch"  }
    }Else{
    $folders  = ls D:\Video -Directory 
    }
    if (!$folders)
    {
     break
    }

    #$folderSource  = $folders | ?{$_.name -eq "test"}
    $folderSource  = $folders | sort LastWriteTime | select -First 1

    cd 'C:\Program Files\HandBrake'

    $FIleTarget = "D:\264\$($folderSource.name).mkv"

    $command = '.\HandBrakeCLI.exe -i "' + $($folderSource.FullName) + '" -o "' + $FileTarget + '" --preset="Super HQ 1080p30 Surround" -s "1,2,3,4,5,6"'
    #$command = '.\HandBrakeCLI.exe -i "' + $($folderSource.FullName) + '" -o "' + $FileTarget + '" -e x264  -q 20.0 -a 1 -E faac -B 160 -6 dpl2 -R Auto -D 0.0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset veryfast --h264-profile main --h264-level 4.0 -s "1,2,3,4,5,6"'
    #$expresion  = 'cmd /c "'+ $command + '"'

    Invoke-Expression $command

}