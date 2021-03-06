#This script will do the following:

#  - Read input parameters from the script '1InputParameters'
#  - Import terms to the term set 'Product Hierarchy' from a .csv file
#  - Creates the custom property 'ItemCategoryNumber' and sets a term set value ID for each term

# ******************************************* #

# Get location of the script folder
function Get-ScriptDirectory 
{ 
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value 
    Split-Path $Invocation.MyCommand.Path 
} 

# Load up our common functions 
$commons = Join-Path (Get-ScriptDirectory) "1InputParameters.ps1"
. $commons


if ($productCatalogSiteCollectionURL -eq "") {
    Write-Host "Enter the URL of the Site Collection, e.g. http://www.hostname.com/sites/catalog " 
    $productCatalogSiteCollectionURL = Read-Host "URL "    
}

if ($TaxonomyInpFile -eq "") {
    Write-Host "Enter the name (with path) for the Taxonomy Input File, e.g. .\Taxonomy.csv " 
    $TaxonomyInpFile = Read-Host "Taxonomy Input File "    
}


# the address of the term store
$termSetName     = "Product Hierarchy"
$SpSite          = Get-SPSite $productCatalogSiteCollectionURL
$taxonomySession = Get-SPTaxonomySession -Site $SpSite

$termStore      = $taxonomySession.DefaultSiteCollectionTermStore
$termStoreName  = "Site Collection - " + $productCatalogSiteCollectionURL.Replace("http://","").Replace("/","-").Replace(":","-")
$termStoreGroup = $termStore.Groups[$termStoreName]
$termSetName    = "Product Hierarchy"
$termSet        = $termStoreGroup.TermSets[$termSetName]

if (!$TaxonomyInpFile.contains(":\"))
{
    $TaxonomyInpFile = Join-Path (Get-ScriptDirectory) $TaxonomyInpFile
}

# Import CVS file
$data = import-csv $TaxonomyInpFile -delimiter "`t"

#Loop data from CVS and add to list 

$list = @{}
$cnt  = $data.Count
$i    = 0
foreach ($rec in $data)
{
    $i = $i + 1
    foreach ($elem in $rec)
    {
        if($elem.ParentId)
        {
            # Get term of parent and use it when creating the new term
            $term = $list[$elem.ParentId]
            $term = $term.CreateTerm($elem.Name, 1033)
        }
        else 
        {
            # Top node term
            $term= $termSet.CreateTerm($elem.Name, 1033)
        }
                
        # Set custom property & store term id in hash table
        $term.SetCustomProperty("ItemCategoryNumber", $elem.Id)
        $list.($elem.Id) = $term
    }
    $p = [math]::Ceiling(($i/$cnt) * 100)

    write-progress -activity "Term store import progress" -status "$p% Complete:" -percentcomplete $p;
}
   
# Commit changes
$termstore.CommitAll()

Write-host " -- Done --"