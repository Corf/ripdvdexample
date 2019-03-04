$folders  = ls D:\Video -Directory
$files = ls D:\264\OK  -File
$names = $files | %{($_.name -split "\.")[0]} | sort

$deleteFolders = $folders | ?{$names -contains $_.name}

foreach ($folder in $deleteFolders)
{
    

        "Deleting $($folder.name)"
        $folder | Remove-Item -Recurse -force -Confirm:$false -ErrorAction SilentlyContinue

}