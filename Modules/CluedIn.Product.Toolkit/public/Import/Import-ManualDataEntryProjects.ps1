function Import-ManualDataEntryProjects {
    <#
        .SYNOPSIS
        Imports manual data entry projects

        .DESCRIPTION
        Imports manual data entry projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-ManualDataEntryProjects -RestorePath "c:\backuplocation"

        This will import all of the manual data entry projects
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    # Variables
    $manualDataEntryProjectsPath = Join-Path -Path $RestorePath -ChildPath 'ManualDataEntryProjects'

    Write-Host "INFO: Importing Manual Data Entry Projects" -ForegroundColor 'Green'
    $manualDataEntryProjects = Get-ChildItem -Path $manualDataEntryProjectsPath -Filter "*ManualDataEntryProject.json" -Recurse
    $currentManualDataEntryProjects = Get-CluedInManualDataEntryProjects
    $currentManualDataEntryProjectObjects = $currentManualDataEntryProjects.data.management.manualDataEntryProjects.data

    $currentFormFields = @()
    foreach ($manualDataEntryProject in $manualDataEntryProjects) {
        $manualDataEntryProjectJson = Get-Content -Path $manualDataEntryProject.FullName | ConvertFrom-Json -Depth 20
        $manualDataEntryProjectObject = $manualDataEntryProjectJson.data.management.manualDataEntryProject

        Write-Host "Processing Manual Data Entry Project: $($manualDataEntryProjectObject.title)" -ForegroundColor 'Green'

        $vocabulary = Get-CluedInVocabulary -Search $manualDataEntryProjectObject.vocabulary.vocabularyName -HardMatch

        if (!$vocabulary.data.management.vocabularies.data) { 
            Write-Warning "Vocabulary '$($manualDataEntryProjectObject.vocabulary.vocabularyName)' not found. This vocabulary is required to import the manual data entry project. Skipping $($manualDataEntryProjectObject.title)"; 
            continue 
        }

        if ($vocabulary.data.management.vocabularies.total -ne 1) {
            Write-Warning "Multiple vocabularies were returned '$($manualDataEntryProjectObject.vocabulary.vocabularyName)'. Skipping $($manualDataEntryProjectObject.title)" 
            continue
        }

        $vocabularyId = $vocabulary.data.management.vocabularies.data.vocabularyId

        if ($manualDataEntryProjectObject.title -notin $currentManualDataEntryProjectObjects.title) {
            Write-Host "Creating Manual Data Entry Project '$($manualDataEntryProjectObject.title)'" -ForegroundColor 'Cyan'

            # Check for existing entity type
            $entityTypeResult = Get-CluedInEntityType -Search $($manualDataEntryProjectObject.entityTypeConfiguration.displayName)
            $newEntityType = $entityTypeResult.data.management.entityTypeConfigurations.total -lt 1

            $manualDataEntryProjectResult = New-CluedInManualDataEntryProject -VocabularyId $vocabularyId -newEntityTypeConfiguration $newEntityType -Object $manualDataEntryProjectObject

            Check-ImportResult -Result $manualDataEntryProjectResult

            $manualDataEntryProjectId = $manualDataEntryProjectResult.data.management.createManualDataEntryProject.id
            $currentFormFields = @()

            $createdProject = Get-CluedInManualDataEntryProject -Id $manualDataEntryProjectId

            $manualDataEntryProjectAnnotationId = $createdProject.data.management.manualDataEntryProject.annotationId

        }
        else {
            $currentManualDataEntryProject = ($currentManualDataEntryProjectObjects | Where-Object { $_.title -eq $manualDataEntryProjectObject.title })
            if ($currentManualDataEntryProject.count -ne 1) {
                Write-Warning "Multiple Manual Data Entry Projects returned. Skipping $($manualDataEntryProjectObject.title)"
                continue 
            }

            Write-Host "Updating Manual Data Entry Project" -ForegroundColor 'Cyan'
            $updateManualDataEntryProjectResult = Set-CluedInManualDataEntryProject -Id $currentManualDataEntryProject.id -VocabularyId $vocabularyId -Object $manualDataEntryProjectObject
            Check-ImportResult -Result $updateManualDataEntryProjectResult

            $manualDataEntryProjectId = $currentManualDataEntryProject.id

            $currentFormFields = $currentManualDataEntryProject.formFields

            $manualDataEntryProjectAnnotationId = $currentManualDataEntryProject.annotationId
        }

        # Form Fields
        if($manualDataEntryProjectObject.formFields.count -eq 0) { Write-Host "No form fields to process" -ForegroundColor 'Cyan' }
        foreach ($manualDataEntryFormField in $manualDataEntryProjectObject.formFields) {
            # Get Vocabulary Key for form field
            $vocabularyKey = Get-CluedInVocabularyKey -KeyName $manualDataEntryFormField.vocabularyKeyObject.key

            if (!$vocabularyKey.data.management.vocabularyPerKey) { 
                Write-Warning "Vocabulary Key '$($manualDataEntryFormField.vocabularyKeyObject.key)' not found. This vocabulary key is required to import the manual data entry project. Skipping $($manualDataEntryFormField.label)"; 
                continue 
            }

            $VocabularyKeyId = $vocabularyKey.data.management.vocabularyPerKey.vocabularyKeyId

            if ($manualDataEntryFormField.label -notin $currentFormFields.label) {
                # Create Form Field
                Write-Host "Creating Form Field '$($manualDataEntryFormField.label)'" -ForegroundColor 'Cyan'

                $manualDataFormFieldResult = New-CluedInManualDataEntryProjectFormField -ManualDataEntryProjectId $manualDataEntryProjectId -VocabularyKeyId $vocabularyKeyId -Object $manualDataEntryFormField
                Check-ImportResult -Result $manualDataFormFieldResult
            }
            else {
                # Update Form Field
                $existingFormField = ($currentFormFields | Where-Object { $_.label -eq $manualDataEntryFormField.label })
                if ($existingFormField.count -ne 1) {
                    Write-Warning "Multiple Form Fields returned. Skipping $($manualDataEntryFormField.label)"
                    continue 
                }

                Write-Host "Updating Form Field" -ForegroundColor 'Cyan'
                $updateFormFieldResult = Set-CluedInManualDataEntryProjectFormField -FormFieldId $existingFormField.id -ManualDataEntryProjectId $manualDataEntryProjectId -VocabularyKeyId $vocabularyKeyId -Object $manualDataEntryFormField
                Check-ImportResult -Result $updateFormFieldResult
            }
        }

        # Annotations
        try {
            Write-Host "Updating annotations" -ForegroundColor 'Cyan'

            $annotationJson = Get-Content -Path (Join-Path -Path $manualDataEntryProjectsPath -ChildPath "$($manualDataEntryProjectObject.id)-Annotation.json") | ConvertFrom-Json -Depth 20
            $annotationObject = $annotationJson.data.preparation.annotation

            # Update Primary Identifier Origin and Primary Identifier vocabulary key
            $updateAnnotationResult = Set-CluedInAnnotation -Id $manualDataEntryProjectAnnotationId -Object $annotationObject
            Check-ImportResult -Result $updateAnnotationResult

            if ($annotationObject.annotationProperties) {
                Write-Host "Updating annotation properties" -ForegroundColor 'Cyan'
                # Update annotation properties 
                $updateAnnotationProperties = Set-CluedInAnnotationProperties -Id $manualDataEntryProjectAnnotationId -Object $annotationObject.annotationProperties
                Check-ImportResult -Result $updateAnnotationProperties
            } else {
                Write-Host "Annotation properties not found, skipping annotation properties update." -ForegroundColor Yellow
            }

        } catch {
            Write-Warning "Annotation file not found for $manualDataEntryProjectId, skipping annotations."
        }
    }
}