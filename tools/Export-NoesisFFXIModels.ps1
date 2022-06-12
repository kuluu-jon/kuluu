#Exports a single skeletal mesh for the specified part in the CSV File.

#Noesis Install Path
$NoesisEXE = "smb://Windows 11._smb._tcp.local/[C] Windows 11/Eden/noesisv4464/Noesis64.exe"

#Rotates the asset so that it appears upright.
$commandArguments = '-rotate 180 -0 -90 -scale 90 -fbxscalehack -fbxsmoothgroups -fbxtexrel -fbxtexext .tga'

#File to open and export *Modified by the CSV file
$ffxiDataSet = 'D:\Utilities\Noesis\Exports\_Scripts\HuMa_Set.ff11datset'
$exportLocation = 'D:\Utilities\Noesis\Exports'

#Dats that enable and disable lines in the DataSet. Disables export of all meshes except the one specified in the CSV file row.
$PartsToCheck = 'head', 'body', 'hands', 'waist', 'legs', 'weapon'

#List of all the Meshes to export. 
#Part = The skeletal mesh to export (head, face, body, waist, etc.); 
#Name = Name the mesh for subfolder (ie. LeatherVest, WarriorBelt, etc.) * NO SPACES
#DatFilePath = Relative path to the dat file
$csvFilePath = 'D:\Utilities\Noesis\Exports\_Scripts\FFXIModelsToExport.csv'


#Start of Script functions!!
$csvMeshes = Import-Csv -Path $csvFilePath -Delimiter ','

foreach ($mesh in $csvMeshes)
{
    #Prepares the  $ffxiDataSet for Noesis Export
    foreach ($part in $PartsToCheck)
    {
        if($part -eq $mesh.part)
        {
            $dat = $mesh.datFilePath
            $regex = ";{0,1}dat `"$part`" `"[a-zA-Z0-9\/._\\]*\.dat`""
            (Get-Content $ffxiDataSet) -replace $regex, "dat `"$part`" `"$dat`"" | Set-Content $ffxiDataSet
        }
        else
        {
            $regex = ";{0,1}(dat `"$part`" `"[a-zA-Z0-9\/]*.dat`")"
            (Get-Content $ffxiDataSet) -replace $regex, ';$1' | Set-Content $ffxiDataSet
        }
    }

    #Creates SubFolder
    if (!(Test-Path -Path $exportLocation\$($mesh.race)_$($mesh.name)))
    {
        New-Item -Path $exportLocation\$($mesh.race)_$($mesh.name) -ItemType Directory
    }

    #Runs Noesis.EXE
    Start-Process -FilePath $NoesisEXE -ArgumentList "?cmode $ffxiDataSet $exportLocation\$($mesh.race)_$($mesh.name)\$($mesh.name).fbx $commandArguments"
    Start-Sleep -Seconds 1
    #& $NoesisEXE ?cmode $ffxiDataSet $exportLocation\$($mesh.race)_$($mesh.name)\$($mesh.name).fbx $commandArguments
}