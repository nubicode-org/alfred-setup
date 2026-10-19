@{
  # windows.ps1 is an interactive installer: Write-Host is how it talks to the person running it.
  ExcludeRules = @('PSAvoidUsingWriteHost')
}
