#----------------------------------------------------------------
# Application: Performance Comparation
#----------------------------------------------------------------

#----------------------------------------------------------------
#Parameters 
#----------------------------------------------------------------
param($server = "",                       #ServerName parameter to connect 
      $user = "",                         #UserName parameter  to connect
      $passwordSecure = "",               #Password Parameter  to connect
      $Db = "",                           #DBName Parameter  to connect
      $Folder = "")                       #Folder Paramater to save the csv files 

#----------------------------------------------------------------
#Function to connect to the database using a retry-logic
#----------------------------------------------------------------

Function GiveMeConnectionSource()
{ 
  for ($i=1; $i -lt 10; $i++)
  {
   try
    {
      logMsg( "Connecting to the database...Attempt #" + $i) (1)
      logMsg( "Connecting to server: " + $server + " - DB: " + $Db) (1)

      $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
      $SQLConnection.ConnectionString = "Server="+$server+";Database="+$Db+";User ID="+$user+";Password="+$password+";Connection Timeout=60;Application Name=PerfCompare" 
      $SQLConnection.Open()
      logMsg("Connected to the database...") (1)
      return $SQLConnection
      break;
    }
  catch
   {
    logMsg("Not able to connect - Retrying the connection..." + $Error[0].Exception) (2)
    Start-Sleep -s 5
   }
  }
}


#-------------------------------------------------------------------------
#Function to obtain the location of ERRORLOG and copy the files to folder 
#-------------------------------------------------------------------------

Function TakeAllErrorLog($FolderDestination)
{ 
   try
    {
   
      $SQLConnectionSource = GiveMeConnectionSource  #Connecting to the database.
      if($SQLConnectionSource -eq $null)
      { 
        logMsg("It is not possible to connect to the database") (2)
        break;
      }

      $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
      $command.CommandTimeout = 6000
      $command.Connection=$SQLConnectionSource
      $command.CommandText = "SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location'"
      $Reader = $command.ExecuteReader()

      while($Reader.Read())
      {
       logMsg("----- File Location: " + $Reader.GetValue(0) ) 
       $Folder = $Reader.GetValue(0)
      }

      $SQLConnectionSource.Close()

      if(TestEmpty($Folder)) 
      {
        logMsg("----- Log Folder is empty" ) (2)
        exit;
      }

      $ErrorLogFolder = @(Get-ChildItem -Path $Folder)
      ForEach($ErrorLogFile in $ErrorLogFolder)
      {
        $sDestination = $FolderDestination + "\" + $ErrorLogFile.Name + ".LOG"
        DeleteFile($sDestination) | out-null
        logMsg("----- Copy the file " + $ErrorLogFile.Name ) 
        Copy-Item $ErrorLogFile -Destination $sDestination | out-null
      }

    }
  catch
   {
    logMsg("Not able to run the errorlog file.." + $Error[0].Exception) (2)
   }
}

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
#delete a file 
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

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)

return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

try
{
Clear

#--------------------------------
#Check the parameters.
#--------------------------------

if (TestEmpty($server)) { $server = read-host -Prompt "Please enter a Server Name" }
if (TestEmpty($server)) 
   {
    LogMsg("Please, specify the server") (2)
    exit;
   }
if (TestEmpty($user))  { $user = read-host -Prompt "Please enter a User Name"   }
if (TestEmpty($user)) 
   {
    LogMsg("Please, specify the user name") (2)
    exit;
   }
if (TestEmpty($passwordSecure))  
    {  
    $passwordSecure = read-host -Prompt "Please enter a password"  -assecurestring  
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
    }
else
    {$password = $passwordSecure} 
if (TestEmpty($password)) 
   {
    LogMsg("Please, specify the password") (2)
    exit;
   }
if (TestEmpty($Db))  { $Db = read-host -Prompt "Please enter a Database Name - Leaving empty the database master will be used"  }
if (TestEmpty($Db)) 
   {
    $DB = "master"
    LogMsg("Using master as DB as default") (2)
   }
if (TestEmpty($Folder)) {  $Folder = read-host -Prompt "Please enter a Destination Folder (Don't include the past \) - Example c:\Perf_Compare" }
if (TestEmpty($Folder)) 
   {
    $Folder = "C:\PERF_Compare"    
    LogMsg("Using " + $Folder + " as default") (2)
   }


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

#Checking if the Instruct.SQL file exists

$ExistFile= Test-Path $File
if($ExistFile -eq 1)
   {
    $query = @(Get-Content $File) 
    logMsg("Instruction file Info "+$query) (1)
   }
else
   {
    logMsg("The file that contains the instructions doesn't exist") (2)
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

 #Reading the errorlog files
 TakeAllErrorLog($sFolderV)

 #Compressing the files
   Remove-Variable password
   logMsg("Zipping the content to " + $Zipfile) (1)
      $result = Compress-Archive -Path $Folder\*.log,$Folder\*.csv -DestinationPath $ZipFile
   logMsg("Zipped the content to " + $Zipfile )  (1)
   logMsg("PERF Compare Script was executed correctly")  (1)
}
catch
  {
    logMsg("PERF Compare Script was executed incorrectly ..: " + $Error[0].Exception) (2)
  }
finally
{
   logMsg("PERF Compare finished - Check the previous status line to know if it was success or not") (2)
} 
