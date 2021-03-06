Framework "4.0"
$buildDir=$psake.build_script_dir
$rootDir=Split-Path $buildDir
$tempDir=$rootDir + "\temp"
$nugetOut=$rootDir +"\nugets"
$nuget=join-path $buildDir "libs\nuget.exe"
$frameworkVersion="Net40"

$slnDir=$rootDir+"\src"
$slnFile=$slnDir+"\SqlFu\SqlFu.csproj"

task default -depends clean, compile, pack

task clean{
   Write-Host "Cleaning..."
   exec { msbuild $slnFile /t:Clean /v:quiet } | Out-Null
   if ((Test-Path $tempDir)) { rd $tempDir -recurse }
   mkdir $tempDir | Out-Null
}

task compile {
    exec { msbuild $slnFile /t:Build /p:Configuration=Release /v:quiet }
}

task pack {
    $current="SqlFu"
    PreNuget $current
	"Updating version..."
	UpdateVersion $current
	"Building package..."
	$nuspec=[string](GetNuspec $current)
	& $nuget pack $nuspec -OutputDirectory $nugetOut
}


#-------------------------------------------- Functions ----------------------

function PreNuget ($current)
{
	$packDir=PackDir($current)
	mkdir $packdir | Out-Null
    
    xcopy "$slnDir\$current\bin\Release\$current.*"  $packdir
	xcopy "$buildDir\$current.nuspec" "$tempDir\$current"
}

function UpdateVersion($current)
{
   #get version
   $asm= [string](PackDir $current) +"\$current.dll"
   $version=[string](GetVersion $asm)
   
   #open nuspec file
   $nuspec= GetNuspec $current
   $specFile=[xml](Get-Content $nuspec)
   
   #update version
   $specFile.package.metadata.version=$version
   
   #get dependencies
   $reqDir="$slnDir\$current\bin\Release"
   $reqs=@(Get-ChildItem $reqDir | Where-Object { $_.Name.EndsWith(".dll")} | Where-Object { $_.Name -ne "$current.dll"} | Select-Object -ExpandProperty Name)
      
   #write deps if any
   if ($reqs.Length -gt 0 )
   {
        Write-Host "Updating " $reqs.Length " dependencies..."
        $depRoot=$specFile.package.metadata.AppendChild($specFile.CreateNode("element","dependencies",""))
        foreach($dep in $reqs)
        {
            $depNode=$depRoot.AppendChild($specFile.CreateElement("dependency"))
            $depNode.SetAttribute("id",$dep.Remove($dep.Length-4)) #remove .dll ending
            $depNode.SetAttribute("version",[string](GetVersion "$reqDir\$dep"))
        }
        
   }
   
   $specFile.Save($nuspec)
   
}

# returns nuspec file path
function GetNuspec($current)
{
return "$tempDir\$current\$current.nuspec"
}

# returns directory path where to place dll which will be packed by nuget
function PackDir($current)
{
return "$tempDir\$current\lib\$frameworkVersion"
}


function GetVersion($asm)
{
 $fileInfo=[System.Diagnostics.FileVersionInfo]::GetVersionInfo($asm)
 [string] $version= $fileInfo.ProductVersion.ToString()
 Write-Host $fileInfo.ProductName "is version $version"
 return $version
}