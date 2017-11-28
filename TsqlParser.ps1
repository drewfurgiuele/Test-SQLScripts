#Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.TransactSql.ScriptDom.dll"
Add-Type -AssemblyName "Microsoft.SqlServer.TransactSql.ScriptDom,Version=13.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"

$ScriptsDirectory = "C:\Test-SQLScripts\Test-SQLScripts\TestScripts"
$ScriptFiles = Get-ChildItem -Path $ScriptsDirectory

$Parser = New-Object Microsoft.SqlServer.TransactSql.ScriptDom.TSql130Parser($true)

$Scripts = @()
$Batches = @()
$Statements = @()

ForEach ($s in $ScriptFiles) {
    $Reader = New-Object System.IO.StreamReader($s.FullName)    
    $Errors= $null
    $Fragment = $Parser.Parse($Reader, [ref] $Errors)

    $HasErrors = $false
    if ($Errors -ne $null) {
        $HasErrors = $true
    }

    $ScriptObject = [System.Management.Automation.PSCustomObject] @{
        NumberOfBatches = $Fragment.Batches.Count
        HasParseErrors = $HasErrors
        Errors = $Errors
        TotalInserts = 0
        TotalUpdates = 0
        TotalDeletes = 0
        NoWhereClauseWarning = $false
        Batches = @()
    }

    ForEach ($b in $Fragment.Batches) {
        $BatchObject = [System.Management.Automation.PSCustomObject] @{
            Statements = @()
        }        
        ForEach ($s in $b.Statments) {
            $StatementObject = [System.Management.Automation.PSCustomObject] @{
                StatementType = $null
                ObjectSchema = $null
                ObjectName = $null
            }
            Switch ($s.PSObject.Properties.Name) {
                InsertSpecification {
                    $ScriptObject.TotalInserts++
                    $StatementObject.StatementType = "DML"
                    $StatementObject.ObjectSchema = $s.InsertSpecification.Target.SchemaObject.SchemaIdentifier.Value
                    $StatementObject.ObjectName = $s.InsertSpecification.Target.SchemaObject.BaseIdentifier.Value
                }
                UpdateSpecification {
                    $ScriptObject.TotalUpdates++                    
                    $StatementObject.StatementType = "DML"
                    $StatementObject.ObjectSchema = $s.UpdateSpecification.Target.SchemaObject.SchemaIdentifier.Value
                    $StatementObject.ObjectName = $s.UpdateSpecification.Target.SchemaObject.BaseIdentifier.Value
                }
                Definition {
                    $StatementObject.StatementType = "DDL"
                    $StatementObject.ObjectSchema = $s.SchemaObjectName.SchemaIdentifier.Value
                    $StatementObject.ObjectName = $s.SchemaObjectName.BaseIdentifier.Value
                }
            }
            $BatchObject.Statements += $StatementObject
        }
        $ScriptObject.Batches += $BatchObject
    }

    $Reader.Close()
    $Reader.Dispose()

    $ScriptObject
}

