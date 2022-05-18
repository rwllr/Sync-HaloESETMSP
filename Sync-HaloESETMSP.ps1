Import-Module HaloHelper.psm1
Import-Module ESETHelper.psm1

function Sync-ESETLicenses
{
  $AllHaloLicenses = Invoke-HaloRestMethod -Endpoint "api/softwarelicence?pageinate=true&page_size=1000&page_no=1"

  ### ESET RELATED STUFF ###

  $currentUser = Invoke-ESETRestMethod -Method GET -Endpoint "https://mspapi.eset.com/api/User/Current"
  $mspCompanyID = $currentUser.company.companyID

  $take = 25
  $a = 0

  $AllCustomers = do {
  $body = @{
      "companyId" = $mspCompanyID
      "skip" = $a*$take
      "take" = $take
    }
  $body = ConvertTo-Json -Depth 10 $body
  $customers = (Invoke-ESETRestMethod -Method POST -Endpoint "https://mspapi.eset.com/api/Company/Children" -Body $body).companies
  $a++
  $customers 
  } while ($customers.count -eq $take)

  $take = 25
  $a = 0

  $AllLicenses = do {
  $body = @{
      "from" = (Get-Date).AddDays(-8).ToString("yyyy-MM-dd")
      "to" = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
      "skip" = $a*$take
      "take" = $take
    }
  $body = ConvertTo-Json -Depth 10 $body
  $licenses = Invoke-ESETRestMethod -Method POST -Endpoint "https://mspapi.eset.com/api/UsageReport/AllCompanies/products" -Body $body
  $a++
  $licenses
  } while ($licenses.count -eq $take)

  # Add product counts to each customer object
  $AllCustomers = $AllCustomers | ForEach-Object {
      $tempcustomer = $_
      $body = @{
          "companyId" = $_.publicId
        }
      $body = ConvertTo-Json -Depth 10 $body
      $customer = (Invoke-ESETRestMethod -Method POST -Endpoint "https://mspapi.eset.com/api/Company/Detail" -Body $body)
      $customer | Add-Member -NotePropertyName "productCounts" -NotePropertyValue $($AllLicenses.companies | Where { $_.companyId -eq $tempcustomer.publicId }).products
      $customer

  }
  # Build the Halo licensing object for each ESET licensing object
  $licenseBodies = $AllCustomers | Where { $_.customIdentifier -match 'HALO(\w+):(\d+)' } | ForEach-Object {
      $customer = $_
      $haloSiteId = [regex]::Matches($customer.customIdentifier, 'HALOSITE:(\d+)')
      $haloCustomerId = [regex]::Matches($customer.customIdentifier, 'HALOCUSTOMER:(\d+)')
      if ($haloSiteId) { 
          $haloSiteId = $haloSiteId.Groups[1].Value
          $haloCustomerId = (Get-HaloSite -SiteID $haloSiteId).client_id }
      else {
          $haloCustomerId = $haloCustomerId.Groups[1].Value
          $haloSiteId = -1
      }
      $CompanyLicenses = $AllHaloLicenses.licences | Where {($_.site_id -eq $haloSiteId) -and ($_.client_id -eq $haloCustomerId)}
      $customer.productCounts | ForEach-Object {
          $productCount = $_
          $body = @{
              "client_id" = $haloCustomerId
              "site_id" = $haloSiteId
              "count" = $productCount.seats
              "id" = ($CompanyLicenses | Where {$_.name -eq $productCount.name}).id
              #"licences_in_use" = $productCount.seats
              "name" = $productCount.name
          }
          $body        
      }

  }

  $body = ConvertTo-Json -Depth 10 @($licenseBodies)
  Invoke-HaloRestMethod -Endpoint "api/SoftwareLicence" -Method POST -Body $body # POST THE SHIZZ TO HALO
  # HALO ONLY UPDATES IF THERE ARE CHANGES
}

$null = Connect-ESETAPI -Username "esetaccount@example.org" -Password "esetpassword"
Sync-ESETLicenses
