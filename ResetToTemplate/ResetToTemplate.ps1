# ***********************************************************************
# * DISCLAIMER: This sample code is provided to members of the 
# * OSIsoft Virtual Campus (vCampus) program (http://vCampus.osisoft.com) 
# * and is subject to the vCampus End-User License Agreement, found at 
# * http://vCampus.osisoft.com/content/OSIsoftUserDownloadAgreement.aspx.
# * 
# * All sample code is provided by OSIsoft for illustrative purposes only.
# * These examples have not been thoroughly tested under all conditions.
# * OSIsoft provides no guarantee nor implies any reliability, 
# * serviceability, or function of these programs.
# * ALL PROGRAMS CONTAINED HEREIN ARE PROVIDED TO YOU "AS IS" 
# * WITHOUT ANY WARRANTIES OF ANY KIND. ALL WARRANTIES INCLUDING 
# * THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY
# * AND FITNESS FOR A PARTICULAR PURPOSE ARE EXPRESSLY DISCLAIMED.
# ************************************************************************
param(
    [Parameter(Position=0,Mandatory=$false)]
    [string] $AFServerName = "localhost",
    
    [Parameter(Position=1,Mandatory=$true)]
    [string] $AFDatabaseName,
    
    [Parameter(Position=2,Mandatory=$true)]
    [string] $AFElementTemplateName
)

[Reflection.Assembly]::LoadFile('C:\Program Files (x86)\PIPC\AF\PublicAssemblies\OSIsoft.AFSDK.dll')

$PISystems = new-object OSIsoft.AF.PISystems
$PISystem = $PISystems[$AFServerName]
if($AFDatabaseName)
{
    $AFDatabase = $PISystem.Databases[$AFDatabaseName]
}
else
{
    $AFDatabase = $PISystem.Databases.DefaultDatabase
}
    
if(!$AFElementNameFilter)
{
    $AFElementNameFilter = "*"
}

$AFElementTemplate = $AFDatabase.ElementTemplates[$AFElementTemplateName]

$AFElements = $null
$SearchIndex = 0
$PageSize = 1000
$SearchedResult = 0

$AFElements = [OSIsoft.AF.Asset.AFElement]::FindElementsByTemplate($AFDatabase, $null, $AFElementTemplate, $TRUE, [OSIsoft.AF.AFSortField]::Name, [OSIsoft.AF.AFSortOrder]::Ascending, $SearchIndex, $PageSize, [ref] $SearchedResult)

write-output $SearchedResult
    
while ($SearchedResult -gt 0 -and $SearchIndex -le $SearchedResult)
{
    foreach($AFElement in $AFElements)
    {
        write-output $AFElement.Name
        foreach($AFAttribute in $AFElement.Attributes)
        {
            if($AFAttribute.Template)
            {
                # * if the attribute have different data reference from the template, reset with template's data reference
                if($AFAttribute.Template.DataReferencePlugIn -ne $AFAttribute.DataReferencePlugIn)
                {
                    $AFAttribute.DataReferencePlugIn = $AFAttribute.Template.DataReferencePlugIn
                }
                # * if attribute's data reference is not null and attribute's config string is difference from template. reset with template's config string
                if($AFAttribute.DataReferencePlugIn)
                {
                    if ($AFAttribute.ConfigString -ne $AFAttribute.Template.ConfigString)
                    {
                        $AFAttribute.ConfigString = $AFAttribute.Template.ConfigString 
                    }
                }
                # * if attribute's data reference is null, resetting means taking the template's default value
                else
                {
                    $AFAttribute.SetValue($AFAttribute.Template.GetValue($null), $null)
                }    
            }
        }	
    }
	
	$SearchIndex = $SearchIndex + $PageSize
	$AFElements = [OSIsoft.AF.Asset.AFElement]::FindElementsByTemplate($AFDatabase, $null, $AFElementTemplate, $TRUE, [OSIsoft.AF.AFSortField]::Name, [OSIsoft.AF.AFSortOrder]::Ascending, $SearchIndex, $PageSize, [ref] $SearchedResult)
}

$AFDatabase.CheckIn()