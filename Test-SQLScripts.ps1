[cmdletbinding()]
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)
    ] [System.IO.FileInfo] $Files,
    [Parameter(Mandatory=$false)] [string] $PathToScriptDomLibrary = $null,
    [Parameter(Mandatory=$false)] [string] $UseQuotedIdentifier = $true
)


begin {
    $LibraryLoaded = $false
    $LibraryVersions = @(13,12,11)
    ForEach ($v in $LibraryVersions)
    {
        if (!$LibraryLoaded) {
            try {
                Add-Type -AssemblyName "Microsoft.SqlServer.TransactSql.ScriptDom,Version=$v.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"  -ErrorAction SilentlyContinue
                $ParserNameSpace = "Microsoft.SqlServer.TransactSql.ScriptDom.TSql" + $v + "0Parser"
                Write-Verbose "Loaded version $v.0.0.0 of the ScriptDom library."
                $LibraryLoaded = $true                
            } catch {
                Write-Verbose "Couldn't load version $v.0.0.0 of the ScriptDom library."
            }
        }
    }
    $Parser = New-Object $ParserNameSpace($true)
    $ParserKeys = @()

    Class ParserKey {
        [string] $ObjectType
        [string] $SchemaSpecification
        [string] $TallyVariable
        ParserKey ([string] $ObjectType, [string] $SchemaSpecification, [string] $TallyVariable) {
            $this.ObjectType = $ObjectType
            $this.SchemaSpecification = $SchemaSpecification
            $this.TallyVariable = $TallyVariable
        }
    }

    $ParserKeys += New-Object Parserkey ("InsertStatement","InsertSpecification.Target.SchemaObject","InsertStatements")
    $ParserKeys += New-Object Parserkey ("UpdateStatement","UpdateSpecification.Target.SchemaObject","UpdateStatements")
    $ParserKeys += New-Object Parserkey ("DeleteStatement","DeleteSpecification.Target.SchemaObject","DeleteStatements")
    $ParserKeys += New-Object Parserkey ("AlterTableAddTableElementStatement","SchemaObjectName",$null)
    $ParserKeys += New-Object Parserkey ("DropIndexStatement","DropIndexClauses.Object","IndexDrops")
    $ParserKeys += New-Object Parserkey ("CreateIndexStatement","OnName",$null)
    $ParserKeys += New-Object Parserkey ("CreateProcedureStatement","ProcedureReference.Name",$null)
    $ParserKeys += New-Object Parserkey ("DropProcedureStatement","Objects",$null)
}


process {
    ForEach ($f in $Files) {
        $CurrentFileName = $f.FullName 
        Write-Verbose "Parsing $CurrentFileName..."
        $Reader = New-Object System.IO.StreamReader($f.FullName)    
        $Errors= $null
        $Fragment = $Parser.Parse($Reader, [ref] $Errors)

        [bool] $HasErrors = $false
        if ($Errors -ne $null) {
            [bool] $HasErrors = $true
        }

        $ScriptObject = [PSCustomObject] @{
            PSTypeName = "Parser.DOM.Script"
            ScriptName = $f.Name
            ScriptFilePath = $f.FullName
            NumberOfBatches = $Fragment.Batches.Count
            HasParseErrors = $HasErrors
            Errors = $Errors
            InsertStatements = 0
            UpdateStatements = 0
            DeleteStatements = 0
            IndexDrops = 0
            NoWhereClauseWarning = $false
            Batches = @()
        }

        Add-Member -InputObject $ScriptObject -Type ScriptMethod -Name ToString -Value { $this.psobject.typenames[0] } -Force

        
        $TotalBatches = 0
        ForEach ($b in $Fragment.Batches) {
            $TotalBatches++;

            $BatchObject =  [pscustomobject] @{
                PSTypeName = "Parser.DOM.Batch"
                ScriptName = $f.Name
                BatchNumber = $TotalBatches
                Statements = @()
            }

            Add-Member -InputObject $BatchObject -Type ScriptMethod -Name ToString -Value { $this.psobject.typenames[0] } -Force

            $TotalStatements = 0
            ForEach ($s in $b.Statements) {
                $TotalStatements++
                $StatementObject = [PSCustomObject] @{
                    PSTypeName = "Parser.DOM.Statement"
                    ScriptName = $f.Name
                    BatchNumber= $TotalBatches
                    StatementNumber = $TotalStatements
                    StatementType = $null
                    Action = $null
                    OnObjectSchema = $null
                    OnObjectName = $null
                }

                Add-Member -InputObject $StatementObject -Type ScriptMethod -Name ToString -Value { $this.psobject.typenames[0] } -Force
                
                $StatementObject.Action = ($s.ScriptTokenStream | Where-Object {$_.Line -eq $s.StartLine -and $_.Column -eq $s.StartColumn }).Text
                
                $TallyVariable = ($ParserKeys | Where-Object {$_.ObjectType -eq $s.gettype().name}).TallyVariable
                if ($TallyVariable -ne "") {
                    $ScriptObject.$TallyVariable++
                }

                $Property = $s
                $SplitDefinition = (($ParserKeys | Where-Object {$_.ObjectType -eq $s.gettype().name}).SchemaSpecification).Split(".")
                ForEach ($def in $SplitDefinition) {
                    $Property = $Property | Select-Object -ExpandProperty $def
                }
                $StatementObject.OnObjectSchema = $Property.SchemaIdentifier.Value
                $StatementObject.OnObjectName = $Property.BaseIdentifier.Value



                $BatchObject.Statements += $StatementObject
            }
            $ScriptObject.Batches += $BatchObject
        }

        $Reader.Close()

        $ScriptObject
    }
}

end {
    $Reader.Dispose()
}