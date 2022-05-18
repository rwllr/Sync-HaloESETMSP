function global:Connect-ESETAPI
{
    param([string]$Username, [String]$Password)
    $loginHeader = @{
        "password" = $Password
        "username" = $Username
      }
    $response = Invoke-RestMethod -Uri "https://mspapi.eset.com/api/Token/Get" -Method POST -Body $($loginHeader | ConvertTo-Json) -ContentType "application/json"
    $script:ESETAPIAuthHeader = @{ Authorization = "Bearer $($Response.AccessToken)" }
    return $script:ESETAPIAuthHeader
}

function global:Invoke-ESETRestMethod
{
    param($Endpoint, [string]$Method="Get", $Body, [Hashtable]$Parameters)
    #$Url = "$($script:BaseUri)$($Endpoint)"
    $Url = "$($Endpoint)"
    if($Parameters)
    {
        $Url = Add-UriQueryParameter -Uri $Url -Parameter $Parameters
    }
    $BodyParam = @{}
    if($Body)
    {
        $BodyParam.Body = $Body
    }
    Write-Verbose $Url
    $responseData = Invoke-RestMethod $Url -Headers $script:ESETAPIAuthHeader -ContentType "application/json" -Method $Method @BodyParam
    Write-Verbose ($responseData | fl * | Out-String)
    return $responseData
}
