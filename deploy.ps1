param (
    [Parameter(Mandatory)]
    [ValidateSet('id', 'solr', 'ce_pre', 'db_users', 'ce_ops', 'ce_shops', 'ce_auth', 'ce_minions', 'db_images', 'ce_init', 'ce_post', 'bizfx', 'xc_ma', 'ceconnect', 'cd', 'cm1', 'cm2', 'xc_xconn', 'sf')]
    [string] $role
)

Function WorkAround-Replace-In-File {
    param(
        [string]$filePath,
        [string]$find,
        [string]$replace
    )
    ((Get-Content -path $filePath -Raw) -replace $find, $replace) | Set-Content -Path $filePath
}

Function Get-DataForxConnect() {
    $SourceDir = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm"
    # XP1.search
    Copy-Item -Path (Join-Path $SourceDir "bin/Sitecore.Commerce.Connect.Collection.Model.dll") -Destination "C:\inetpub\wwwroot\XP1.search\bin\"
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Models/Sitecore.Commerce.Connect.XConnect.Models.json") -Destination "C:\inetpub\wwwroot\XP1.search\App_Data\Models\"
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Models/Sitecore.Commerce.Connect.XConnect.Models.json") -Destination "C:\inetpub\wwwroot\XP1.search\App_Data\jobs\continuous\IndexWorker\App_Data\Models"
    # XP1.collection
    Copy-Item -Path (Join-Path $SourceDir "bin/Sitecore.Commerce.Connect.Collection.Model.dll") -Destination "C:\inetpub\wwwroot\XP1.collection\bin\"
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Models/Sitecore.Commerce.Connect.XConnect.Models.json") -Destination "C:\inetpub\wwwroot\XP1.collection\App_Data\Models\"
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Configs/sc.XConnect.Collection.Model.Commerce.Plugins.xml") -Destination "C:\inetpub\wwwroot\XP1.collection\App_Data\Config\Sitecore\Collection"
    # XP1.ma
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Configs/sc.XConnect.Segmentation.Commerce.Predicates.xml") -Destination "C:\inetpub\wwwroot\XP1.ma\App_Data\jobs\continuous\AutomationEngine\App_Data\Config\sitecore\Segmentation"
    # XP1.refdata
    Copy-Item -Path (Join-Path $SourceDir "bin/Sitecore.Commerce.Connect.Collection.Model.dll") -Destination "C:\inetpub\wwwroot\XP1.refdata\bin\"
    Copy-Item -Path (Join-Path $SourceDir "XConnectFiles/Models/Sitecore.Commerce.Connect.XConnect.Models.json") -Destination "C:\inetpub\wwwroot\XP1.refdata\App_Data\Models\"
}

Function WorkAround-Data-For-MA {
    $packageName = "Sitecore Commerce Marketing Automation for AutomationEngine 14.0.27.zip"
    $packagesPath = ".."
    Expand-Archive -Path ((Get-Item -Path (Join-Path $packagesPath $packageName)).FullName) -DestinationPath "C:\inetpub\wwwroot\XP1.ma" -Force
}

Function WorkAround-CE-PRE {
    WorkAround-Fake-Xconnect
    WorkAround-Fake-Solr
    WorkAround-Fake-Redis
    New-Item -Path "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\" -Name "XP1.sc" -ItemType "directory" -ErrorAction SilentlyContinue
    $SiteParams = @{
        Name            = "XP1.sc"
        ApplicationPool = "XP1.sc"
        PhysicalPath    = "c:\inetpub\wwwroot"
    }
    Invoke-WebsiteTask @SiteParams
}

Function WorkAround-Copy-SXA {
    $packageName = "Sitecore Experience Accelerator 9.3.0.2589 CD.zip"
    $packagesPath = ".."
    $extractionPath = (Join-Path $PWD "tmp")
    Expand-Archive -Path ((Get-Item -Path (Join-Path $packagesPath $packageName)).FullName) -DestinationPath $extractionPath -Force
    Expand-Archive -Path ((Get-Item -Path (Join-Path $extractionPath "package.zip")).FullName) -DestinationPath $extractionPath -Force
    Copy-Item -Path (Join-Path $PWD "tmp/files/*") -Destination "C:\inetpub\wwwroot\XP1.cd\" -Recurse -Force
}

Function WorkAround-Fake-SC {
    Write-Host "WorkAround-Fake-SC"
    New-Item -Path "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\" -Name "XP1.sc" -ItemType "directory"
}

Function WorkAround-Fake-Solr {
    Write-Host "WorkAround-Fake-Solr"
    New-Item -Path "$($Env:SYSTEMDRIVE)\" -Name "solr-8.1.1" -ItemType "directory" -ErrorAction SilentlyContinue
}

Function WorkAround-Fake-Xconnect {
    Write-Host "WorkAround-Fake-Xconnect"
    New-Item -Path "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\" -Name "XP1.xconnect" -ItemType "directory" -ErrorAction SilentlyContinue
}

Function WorkAround-Fake-Redis {
    Write-Host "WorkAround-Fake-Redis"
    New-Item -Path "$($Env:SYSTEMDRIVE)\Program Files\" -Name "Redis" -ItemType "directory" -ErrorAction SilentlyContinue
}

Write-Host ">> Doing workarounds for [$role]"
switch ($role) {
    "id" {
        WorkAround-Fake-SC
        WorkAround-Fake-Redis
        WorkAround-Fake-Xconnect
    }
    "solr" {
        WorkAround-Fake-SC
        WorkAround-Fake-Xconnect
    }
    "xc_xconn" {
        Get-DataForxConnect
    }
    "ce_pre" {
        WorkAround-CE-PRE
    }
    "cd" {
        WorkAround-Fake-Xconnect
        WorkAround-Fake-Redis
        WorkAround-Copy-SXA
    }
    { "cm1", "prc", "db_users" } {
        WorkAround-Fake-Xconnect
        WorkAround-Fake-Redis
    }
    "cm2" {
        WorkAround-Fake-Xconnect
        WorkAround-Fake-Redis
    }
    "xc_ma" {
        WorkAround-Data-For-MA
    }
    { "bizfx", "sf" } {
        WorkAround-Fake-SC
        WorkAround-Fake-Xconnect
        WorkAround-Fake-Solr
        WorkAround-Fake-Redis
    }
}

Write-Host "Running actual deployment"
[string]$tasksToSkip
foreach ($task in (Get-Content -Path (Join-Path $PWD "tasks.json") | ConvertFrom-Json)) {
    if (-Not ($($task.role).Contains($role))) {
        $tasksToSkip += "$($task.taskName),"
    }
}

$tasksToSkip = $tasksToSkip.Substring(0, $tasksToSkip.Length - 1)

& (Join-Path $PWD "Deploy-Sitecore-Commerce.ps1") -TasksToSkip $tasksToSkip
Write-Host "Actual deployment is done"

Write-Host "Running post-steps"
switch ($role) {
    { "id", "xc_ma" } {
        Remove-Item "C:\inetpub\wwwroot\XP1.sc\XConnectFiles" -Recurse -Force -ErrorAction SilentlyContinue
    }
    "cd" {
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.XConnect" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\Program Files\Redis" -Recurse -Force -ErrorAction SilentlyContinue

        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cd\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<shopsServiceUrl>https://localhost:5000/api/</shopsServiceUrl>" -replace "<shopsServiceUrl>https://commerceshops.sc9.com/api/</shopsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cd\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<commerceOpsServiceUrl>https://localhost:5000/commerceops/</commerceOpsServiceUrl>" -replace "<commerceOpsServiceUrl>https://commerceops.sc9.com/commerceops/</commerceOpsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cd\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<commerceMinionsServiceUrl>https://localhost:5000/commerceops/</commerceMinionsServiceUrl>" -replace "<commerceMinionsServiceUrl>https://commerceminions.sc9.com/commerceops/</commerceMinionsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cd\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<sitecoreIdentityServerUrl>https://sxastorefront-identityserver/</sitecoreIdentityServerUrl>" -replace "<sitecoreIdentityServerUrl>https://xp1.identityserver/</sitecoreIdentityServerUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cd\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<enforceSsl>true</enforceSsl>" -replace "<enforceSsl>false</enforceSsl>"
    }
    "cm1" {
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.XConnect" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\Program Files\Redis" -Recurse -Force -ErrorAction SilentlyContinue

        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<configuration>localhost,defaultDatabase=1,allowAdmin=true,syncTimeout=3600000</configuration>" -replace "<configuration>localhost,defaultDatabase=1,allowAdmin=true,abortConnect=false,syncTimeout=3600000</configuration>"
    }
    "cm2" {
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.XConnect" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\Program Files\Redis" -Recurse -Force -ErrorAction SilentlyContinue

        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<shopsServiceUrl>https://localhost:5000/api/</shopsServiceUrl>" -replace "<shopsServiceUrl>https://commerceshops.sc9.com/api/</shopsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<commerceOpsServiceUrl>https://localhost:5000/commerceops/</commerceOpsServiceUrl>" -replace "<commerceOpsServiceUrl>https://commerceops.sc9.com/commerceops/</commerceOpsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<commerceMinionsServiceUrl>https://localhost:5000/commerceops/</commerceMinionsServiceUrl>" -replace "<commerceMinionsServiceUrl>https://commerceminions.sc9.com/commerceops/</commerceMinionsServiceUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<sitecoreIdentityServerUrl>https://sxastorefront-identityserver/</sitecoreIdentityServerUrl>" -replace "<sitecoreIdentityServerUrl>https://xp1.identityserver/</sitecoreIdentityServerUrl>"
        WorkAround-Replace-In-File -filePath "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.cm\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config" -find "<enforceSsl>true</enforceSsl>" -replace "<enforceSsl>false</enforceSsl>"
    }
    "prc" {
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.XConnect" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\Program Files\Redis" -Recurse -Force -ErrorAction SilentlyContinue
    }
    { "ce_post", "bizfx", "sf" } {
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.sc" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\XP1.xconnect" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\solr-8.1.1" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($Env:SYSTEMDRIVE)\Program Files\Redis" -Recurse -Force -ErrorAction SilentlyContinue
    }
}