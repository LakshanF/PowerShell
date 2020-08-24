
param
(
    [string]$testFile=".\TestFiles\Default.txt",
    [bool]$runSFDefault=$true,
    [string]$outFile=".\out\TestRunInfo.txt"
)


Write-Host "Starting..."

#proj files
$defaultProj=".\ProjectFiles\Default.csproj"
$testLibProj=".\ProjectFiles\TestLibrary.csproj"
$defaultSFProj=".\ProjectFiles\Default_SF_Trim.csproj"
$testLibSFProj=".\ProjectFiles\TestLibrary_SF_Trim.csproj"

if($runSFDefault)
{
    $defaultProj=$defaultSFProj
    $testLibProj=$testLibSFProj
}

$projFileName=".\RunTimeTests.csproj"

#global vars
$fileMain=".\Program.cs"
#$exeName="D:\work\Core\Test\RuntimeTests\bin\Release\net5.0\win-x64\publish\RunTimeTests.exe"

Write-Host $defaultProj
Write-Host $testLibProj


function Cleanup
{
    if(Test-Path $projFileName){
        Remove-Item $projFileName -Force
    }
    if(Test-Path $fileMain){
        Remove-Item $fileMain -Force
    }
    $dirName="obj"
    if(Test-Path $dirName){
        Remove-Item $dirName -Force -Recurse
    }
    $dirName="bin"
    if(Test-Path $dirName){
        Remove-Item $dirName -Force -Recurse
    }
}


if(Test-Path $outFile){
    Remove-Item $outFile -Force
}
ForEach($line in Get-Content $testFile){
    if(-not [string]::IsNullOrEmpty($line))
    {
        #clean up
        Cleanup

        $writeStr="Starting "+ $line
        Out-File -FilePath $outFile -Append -InputObject $writeStr

        Copy-Item $line -Destination $fileMain -Force

        #copy the right csproj file
        #check csproj file to see if testlibrary is needed
        $projFile = [io.path]::Combine([io.path]::GetDirectoryName($line),([io.path]::GetFileNameWithoutExtension($line) + ".csproj"))
        #Write-Host $projFile
        $SEL = Select-String -Path $projFile -Pattern "CoreCLRTestLibrary"
        if ($null -ne $SEL)
        {
            Copy-Item $testLibProj -Destination $projFileName -Force
        }
        else
        {
            Copy-Item $defaultProj -Destination $projFileName -Force
        }

        $output = (dotnet publish)
        if ($lastexitcode -ne 0)
        {
            $writeStr="Error "+ $output
            Out-File -FilePath $outFile -Append -InputObject $writeStr
        }else
        {
            #@TODO - passing this as $exeName doesnt work
            $output = (D:\work\Core\Test\RuntimeTests\bin\Release\net5.0\win-x64\publish\RunTimeTests.exe)
            $writeStr="Test Output "+ $lastexitcode
            Out-File -FilePath $outFile -Append -InputObject $writeStr
        }

        $writeStr="Completed "+ $line
        Out-File -FilePath $outFile -Append -InputObject $writeStr
    }
}

#clean up
Cleanup

Write-Host "Done.."