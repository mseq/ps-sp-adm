#Parameters
param ($SiteURL, $ListName)
if ($SiteURL -eq $null) {
    $SiteURL = Read-Host -Prompt "Qual a URL do SharePoint Site? "
}
if ($ListName -eq $null) {
    $ListName = Read-Host -Prompt "Qual a Lista? "
}
$CsvFileName = $SiteURL.Substring($SiteURL.IndexOf('-')+1, $SiteURL.Length - $SiteURL.IndexOf('-') -1)
 
#Function to get number of Sub-folder and Files count recursively
Function Get-SPOFolderStats
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder
    )
    #Get Sub-folders of the folder
    Get-PnPProperty -ClientObject $Folder -Property ServerRelativeUrl, Folders | Out-Null
 
    #Get the SiteRelativeUrl
    $Web = Get-PnPWeb -Includes ServerRelativeUrl
    $SiteRelativeUrl = $Folder.ServerRelativeUrl -replace "$($web.ServerRelativeUrl)", ""
 
    [PSCustomObject] @{
        Folder    = $Folder.Name
        Path      = $Folder.ServerRelativeUrl
        ItemCount = Get-PnPFolderItem -FolderSiteRelativeUrl $SiteRelativeUrl -ItemType File | Measure-Object | Select -ExpandProperty Count
        SubFolderCount = Get-PnPFolderItem -FolderSiteRelativeUrl $SiteRelativeUrl -ItemType Folder | Measure-Object | Select -ExpandProperty Count
    }
     
    #Process Sub-folders
    ForEach($SubFolder in $Folder.Folders)
    {
        Get-SPOFolderStats -Folder $SubFolder
    }
}
 
#Connect to SharePoint Online
#Connect-PnPOnline $SiteURL -Credentials (Get-Credential)
Connect-PnPOnline $SiteURL -UseWebLogin
 
#Call the Function to Get the Library Statistics - Number of Files and Folders at each level
$FolderStats = Get-PnPList -Identity $ListName -Includes RootFolder | Select -ExpandProperty RootFolder | Get-SPOFolderStats | Sort Path
$FolderStats
 
#Export to CSV
$FolderStats | Export-Csv ".\$CsvFileName-$ListName.csv" -NoTypeInformation


#Read more: https://www.sharepointdiary.com/2019/05/sharepoint-online-get-files-sub-folders-count-in-document-library-using-powershell.html#ixzz6gEGFb28g