#This script will do the following:

#  - Read input parameters from the script '1InputParameters'
#  - Create new site columns
#  - Map newly created site columns to the content type 'Product with Image'


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


$columnlist.("ItemCategoryNumber") = "NUMBER"


if ($productCatalogSiteCollectionURL -eq "") {
    Write-Host "Enter the URL of the Site Collection, e.g. http://www.hostname.com/sites/catalog " 
    $productCatalogSiteCollectionURL = Read-Host "URL "    
}


# Create Site object to reference the product catalog site collection #
$site    = new-object Microsoft.SharePoint.SPSite($productCatalogSiteCollectionURL)

# Initiate site columns object that refers to the site columns of the site collection #
$sitecolumnobject = $site.rootweb.Fields

# Initiate content type object that refers to the OOTB content type Product with Image #
$ProductWithImageContentType  = $site.rootweb.ContentTypes.Item("Product with Image")  # Content Type

# Add the site column listed above with correct type #
foreach ($columnname in $columnlist.Keys)
{
    $columntype = $columnlist[$columnname]

    if (!$sitecolumnobject.ContainsField($columnname)) 
    {
        if ($columntype.ToUpper() -ne "HTML")
        {
            $sitecolumnobject.Add($columnname,$columntype,$false)
        }
        # HTML is a special case, as HTML doesn't exist as a native type in SPFieldType
        elseif ($columntype.ToUpper() -eq "HTML")
        {
            $fieldXML = "<Field Type=""HTML""
                            Name=""$columnname""
                            DisplayName=""$columnname""
                            StaticName=""$columnname""
                            RichTextMode=""FullHtml""
                            RichText=""TRUE""
                            AloowHyperlink=""TRUE""
                            ShowInNewForm=""TRUE"">
                       </Field>"
            $sitecolumnobject.AddFieldAsXml($fieldXML)
        }
    } 

    # Add the site columns to the Product Catalog Columns group #
    $sitecolumn       = $sitecolumnobject.GetField($columnname)
    $sitecolumn.Group = "Product Catalog Columns"
    $sitecolumn.Update()
    $ProductWithImageContentType.FieldLinks.Add($sitecolumn)
    $ProductWithImageContentType.Update(1)
}


Write-host " -- Done --"