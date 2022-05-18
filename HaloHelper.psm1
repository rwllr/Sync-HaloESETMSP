function global:Connect-HaloAPI
{
    param([string]$ClientID, [string]$Secret, [uri]$BaseUri, [string]$HostedTenant)
    $script:BaseUri = $BaseUri
    $script:Tenant  = $HostedTenant
    $AuthReqBody = @{
        grant_type = 'client_credentials'
        client_id = $ClientID
        client_secret = $Secret
        scope = "all"
    }
    $encodedCredentials = ConvertTo-Base64 "$($ClientID):$($Secret)"
    $OauthUrl = "$($BaseUri)auth/token?tenant=$($Tenant)"
    Write-Output $OauthUrl
    $Response = Invoke-RestMethod $OauthUrl -Method Post -Body $AuthReqBody
    $script:HaloAPIAuthHeader = @{ Authorization = "Bearer $($Response.Access_Token)" }
    return $script:HaloAPIAuthHeader
}

function global:Invoke-HaloRestMethod
{
    param($Endpoint, [string]$Method="Get", $Body, [Hashtable]$Parameters)
    # if endpoint doesn't include a ? then we must add & followed by always page_size=1000
    $Url = "$($script:BaseUri)$($Endpoint)"
    if($Parameters)
    {
        $Url = Add-UriQueryParameter -Uri $Url -Parameter $Parameters
    }
    Write-Output "Url: $Url"
    $BodyParam = @{}
    if($Body)
    {
        $BodyParam.Body = $Body
    }
    $responseData = Invoke-RestMethod $Url -Headers $script:HaloAPIAuthHeader -ContentType "application/json" -Method $Method @BodyParam  -Debug -Verbose
    Write-Verbose ($responseData | fl * | Out-String)
    return $responseData
}
