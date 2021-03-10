#----------------------------------------------------------------
# Application: Performance Comparation
#----------------------------------------------------------------

#----------------------------------------------------------------
#Parameters 
#----------------------------------------------------------------
param($server = "", #ServerName parameter to connect 
      $user = "",                          #UserName parameter  to connect
      $passwordSecure = "",              #Password Parameter  to connect
      $Db = "",                       #DBName Parameter  to connect
      $Folder = "C:\PERF_Collector")               #Folder Paramater to save the csv files 

#--------------------------------------------------------------
#Create a folder 
#--------------------------------------------------------------
Function CreateFolder
{ 
  Param( [Parameter(Mandatory)]$Folder ) 
  try
   {
    $FileExists = Test-Path $Folder
    if($FileExists -eq $False)
    {
     $result = New-Item $Folder -type directory 
     if($result -eq $null)
     {
      logMsg("Imposible to create the folder " + $Folder) (2)
      return $false
     }
    }
    return $true
   }
  catch
  {
   return $false
  }
 }

#-------------------------------
#Create a folder 
#-------------------------------
Function DeleteFile{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    $FileExists = Test-Path $FileNAme
    if($FileExists -eq $True)
    {
     Remove-Item -Path $FileName -Force 
    }
    return $true 
   }
  catch
  {
   return $false
  }
 }

#--------------------------------
#Log the operations
#--------------------------------
function logMsg
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=1)]
         [int] $Color
    )
  try
   {
    $Fecha = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $msg = $Fecha + " " + $msg
    Write-Output $msg | Out-File -FilePath $LogFile -Append
    $Colores="White"
    $BackGround = 
    If($Color -eq 1 )
     {
      $Colores ="Cyan"
     }
    If($Color -eq 3 )
     {
      $Colores ="Yellow"
     }

     if($Color -eq 2)
      {
        Write-Host -ForegroundColor White -BackgroundColor Red $msg 
      } 
     else 
      {
        Write-Host -ForegroundColor $Colores $msg 
      } 


   }
  catch
  {
    Write-Host $msg 
  }
}

#--------------------------------
#The Folder Include "\" or not???
#--------------------------------

function GiveMeFolderName([Parameter(Mandatory)]$FolderSalida)
{
  try
   {
    $Pos = $FolderSalida.Substring($FolderSalida.Length-1,1)
    If( $Pos -ne "\" )
     {return $FolderSalida + "\"}
    else
     {return $FolderSalida}
   }
  catch
  {
    return $FolderSalida
  }
}

#--------------------------------
#Validate Param
#--------------------------------
function TestEmpty($s)
{
if ([string]::IsNullOrWhitespace($s))
  {
    return $true;
  }
else
  {
    return $false;
  }
}

#--------------------------------
#Separator
#--------------------------------

function GiveMeSeparator
{
Param([Parameter(Mandatory=$true)]
      [System.String]$Text,
      [Parameter(Mandatory=$true)]
      [System.String]$Separator)
  try
   {
    [hashtable]$return=@{}
    $Pos = $Text.IndexOf($Separator)
    $return.Text= $Text.substring(0, $Pos) 
    $return.Remaining = $Text.substring( $Pos+1 ) 
    return $Return
   }
  catch
  {
    $return.Text= $Text
    $return.Remaining = ""
    return $Return
  }
}

try
{
Clear

#--------------------------------
#Check the parameters.
#--------------------------------

if (TestEmpty($server)) { $server = read-host -Prompt "Please enter a Server Name" }
if (TestEmpty($user))  { $user = read-host -Prompt "Please enter a User Name"   }
if (TestEmpty($passwordSecure))  
    {  
    $passwordSecure = read-host -Prompt "Please enter a password"  -assecurestring  
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
    }
else
    {$password = $passwordSecure} 
if (TestEmpty($Db))  { $Db = read-host -Prompt "Please enter a Database Name"  }
if (TestEmpty($Folder)) {  $Folder = read-host -Prompt "Please enter a Destination Folder (Don't include the past \) - Example c:\Perf_Collector" }

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)

return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

#--------------------------------
#Run the process
#--------------------------------

logMsg("Creating the folder " + $Folder) (1)
   $result = CreateFolder($Folder) #Creating the folder that we are going to have the results, log and zip.
   If( $result -eq $false)
    { 
     logMsg("Was not possible to create the folder") (2)
     exit;
    }
logMsg("Created the folder " + $Folder) (1)

$sFolderV = GiveMeFolderName($Folder) #Creating a correct folder adding at the end \.

$LogFile = $sFolderV + "PERF_Export.Log"    #Logging the operations.
$ZipFile = $sFolderV + "PERF_Export.Zip"    #compress the zip file.
$File    = $sFolderV + "PERF_Instruct.SQL"  #Tables to export and columns to hide

logMsg("Deleting Log and Zip File") (1)
   $result = DeleteFile($LogFile) #Delete Log file
   $result = DeleteFile($ZipFile) #Delete Zip file that contains the results
logMsg("Deleted Log and Zip File") (1)

logMsg("ServerName: " +$server) (1)
logMsg("DB Name: "    +$DB) (1)
logMsg("Reading the instruction file") (1)
$ExistFile= Test-Path $File
if($ExistFile -eq 1)
   {
    $query = @(Get-Content $File) 
    logMsg("Instruction file Info "+$query) (1)
   }
else
   {
    logMsg("The file that contains the instuctions doesn't exist") (2)
    exit;
   }
logMsg("Read the instruction file") (1)  

logMsg("Pre-Processing the tables selected.." ) (1) 
$ArrayQueries  = [System.Collections.ArrayList]@()
[string]$Tmp = ""
[string]$Concat = ""
 for ($iQuery=0; $iQuery -lt $query.Count; $iQuery++) 
 {
  $Tmp=$query[$iQuery]
  $Concat = $Concat + [char]10+[char]13 + $Tmp

  If($Tmp.EndsWith("#"))
   {
    $ArrayQueries.Add($Concat.Replace("#"," ")) | Out-null
    $Concat = ""
   }

 } 

logMsg("Processing the tables selected.." ) (1) 
 for ($iQuery=0; $iQuery -lt $ArrayQueries.Count; $iQuery++) 
 {
  logMsg("Obtaining the data from " + $ArrayQueries[$iQuery]) (1)
    $FileName = Remove-InvalidFileNameChars($ArrayQueries[$iQuery].ToString().Substring(4,12))
    $DBState = Invoke-Sqlcmd -ServerInstance $server -Database $DB -Query $ArrayQueries[$iQuery] -Username $user -Password $password -ConnectionTimeout 60 -QueryTimeout 60 | Select-Object *  | ConvertTo-CSV  | Out-File -filePath ($sFolderV + "Query_" + $FileName +".csv") -Encoding "UTF8"
 } 

   Remove-Variable password
   logMsg("Zipping the content to " + $Zipfile) (1)
      $result = Compress-Archive -Path $Folder\*.log,$Folder\*.csv -DestinationPath $ZipFile
   logMsg("Zipped the content to " + $Zipfile + "--" + $result )  (1)
   logMsg("PERF Collector Script was executed correctly")  (1)
}
catch
  {
    logMsg("PERF Collector Script was executed incorrectly ..: " + $Error[0].Exception) (2)
  }
finally
{
   logMsg("PERF Collector Script finished - Check the previous status line to know if it was success or not") (2)
} 
