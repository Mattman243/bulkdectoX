Function Get-Folder($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
        $folder = $folder + "\*"
    }
    return $folder
}

[String]$Path = 'C:\Scripts\BIN\*'
#[String]$Path = Get-Folder

#Select-String will search given files or input for text matching a regex pattern and return objects with the file path, matched value, and line number. Each matched value is a returned object.
#The values are stored in an array and not passed through the pipeline to avoid the file being locked
$FileMatches = @()
$FileMatches += Select-String -Path $Path -Pattern "(\s)(\d+)" -AllMatches | Select-String -Pattern "name","version","\/\/","table","tcam" -NotMatch | Group-Object -Property "Path"
#Regex pattern to match contiguous numeric characters with leading whitespace character
#Add patterns to -NotMatch to skip lines and remove -AllMatches if you only care about the first match in a line.

$FileMatches | ForEach-Object -Process {       
    $Content = (Get-Content -Path $_.Name)
    $_.Group | ForEach-Object -Process {
        
        [int]$Index = $_.LineNumber - 1
        [int]$Offset = 0
        $_.Matches | ForEach-Object -Process {
            #Select-String tells us the line number so there is no need to iterate through the content we can just replace the line we care about           
            
            [String]$Binary = " 'b" + [convert]::ToString($_.Value,2) #converts matches to binary, while adding back whitespace and 'b identifier
            $Content[$Index] = $Content[$Index].Remove($_.Index + $Offset,$_.length)
            $Content[$Index] = $Content[$Index].Insert($_.Index + $Offset,$Binary)

            $Offset += ($Binary.Length - $_.value.length)
        }
    }
    
    Set-Content -Path $_.Name -Value $Content
}
