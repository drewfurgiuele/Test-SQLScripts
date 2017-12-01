# Test-SQLScripts
Parse a collection of SQL Scripts and look for batches, keywords, and potential issues.

## Description
Hey, do you automate your deployments of SQL Server scripts to your different environments? Do you review every script manually? I don't, and don't plan to start. Instead, let's automate! This function is designed to parse a given list of files to generate a summary of what type of commands are contained in them. The ideal use-case is to point this script to a file list of scripts you're going to run automatically, before you run them, to get an idea of what your changeset contains.

## What do you need?
For this to work, you need a library: `Microsoft.SqlServer.TransactSql.ScriptDom` somewhere on your machine. It'll attempt to Add-Type the library for versions 11,12, and 13. If it can't find it, it'll tell you.

## Usage Example
The script takes a `[System.IO.FileInfo]` input object, which means you can (and should?) pipe the results of `Get-ChildItem` to get a list of your files and then pass that in. Maybe something like this:

`$results = Get-ChildItem .\TestScripts | .\Test-SQLScripts.ps1 -Verbose`

This repository also includes some "unit tests" for the script to simulate some commands (more below in "Test Scenarios")

## What's returned?
This function returns an object that sort of follows the base functionalty of the classes and libraries it uses. The high-level object is a roll-up of sorts that tells you what sort statements are in the scripts, like number of insert/updates/deletes/indexes, etc. If any of the statements in the file don't parse, the Error property will include the error info (which is also an object).

The object also includes a batches property, which is an array of SQL batches in the script. The batches then have a statements property, which contains the individual statements that were parsed. The individual statement objects go into more detail about what the statements are, what they do, and what they affect. To get to that info directly, you'd do this with the object you get back:

```$results = Get-ChildItem .\TestScripts | .\Test-SQLScripts.ps1 -Verbose
$results.Batches.Statements | ft

ScriptName                BatchNumber StatementNumber StatementType Action OnObjectSchema OnObjectName
----------                ----------- --------------- ------------- ------ -------------- ------------
AlterScript.sql                     1               1               ALTER  Person         PErson
DeleteScript.sql                    1               1               DELETE Person         Person
IndexScript.sql                     1               1               CREATE Person         Address
IndexScript.sql                     1               2               DROP   Person         Address
```
This repository also includes some "unit tests" for the script to simulate some commands (more below in "Test Scenarios")

## Test Scenarios
In the TestScripts sub-folder in this repository, I have some quick SQL Scripts I wrote to test different statements. Feel free to add different scripts to this folder and run things against them to see how it returns. If it doesn't parse and return info about them, you'll need to extend the parsing...

## Extending the tests
To simplify adding new statement parsing, check out the ParserKey class I added to the script. All the tests and objects it looks for are defined as a class that is checks against. This will probably be changed to JSON soon, but for now this is how I'm handling the different statement types.
