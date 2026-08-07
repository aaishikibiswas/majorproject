param(
    [string]$Region = "us-east-1",
    [string]$BotName = "MajorProjectHotelBookingBot",
    [string]$RoleArn = ""
)

$ErrorActionPreference = "Stop"

function Invoke-AwsJson {
    param([string[]]$Args)

    $output = & aws @Args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output -join "`n")
    }

    if ([string]::IsNullOrWhiteSpace(($output -join "`n"))) {
        return $null
    }

    return ($output | ConvertFrom-Json)
}

function Invoke-Aws {
    param([string[]]$Args)

    $output = & aws @Args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output -join "`n")
    }

    return $output
}

function Write-JsonFile {
    param(
        [string]$Path,
        [object]$Value
    )
    $Value | ConvertTo-Json -Depth 30 | Set-Content -Path $Path -Encoding utf8
}

$stamp = Get-Date -Format "yyyyMMddHHmmss"
$work = Join-Path $PSScriptRoot "lex-deploy-$stamp"
New-Item -ItemType Directory -Path $work | Out-Null

$trustPath = Join-Path $work "lex-trust-policy.json"
Write-JsonFile $trustPath @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{ Service = "lexv2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }
    )
}

$dataPrivacyPath = Join-Path $work "data-privacy.json"
Write-JsonFile $dataPrivacyPath @{ childDirected = $false }

$roomValuesPath = Join-Path $work "room-type-values.json"
Write-JsonFile $roomValuesPath @(
    @{ sampleValue = @{ value = "Classic" }; synonyms = @(@{ value = "standard" }, @{ value = "basic" }) },
    @{ sampleValue = @{ value = "Deluxe" }; synonyms = @(@{ value = "premium" }, @{ value = "superior" }) },
    @{ sampleValue = @{ value = "Duplex" }; synonyms = @(@{ value = "two level" }, @{ value = "suite" }) },
    @{ sampleValue = @{ value = "Family Suite" }; synonyms = @(@{ value = "family room" }, @{ value = "large suite" }) },
    @{ sampleValue = @{ value = "Presidential Suite" }; synonyms = @(@{ value = "luxury suite" }, @{ value = "executive suite" }) }
)

$intentPath = Join-Path $work "intent.json"
Write-JsonFile $intentPath @{
    messages = @(
        @{
            plainTextMessage = @{
                value = "Your hotel room is booked. Booking summary: {Nights} night(s) from {CheckInDate} to {CheckOutDate} for {Guests} guest(s) in a {RoomType} room. Estimated room price per night: Classic USD 80, Deluxe USD 120, Duplex USD 180, Family Suite USD 220, Presidential Suite USD 350. Please check the selected category to calculate the total for your stay."
            }
        }
    )
}

$closingPath = Join-Path $work "closing-response.json"
Write-JsonFile $closingPath @{
    closingResponse = @{
        messageGroups = @(
            @{
                message = @{
                    plainTextMessage = @{
                        value = "Thanks. Your hotel booking details have been confirmed and the room price and stay duration have been shared."
                    }
                }
            }
        )
        allowInterrupt = $true
    }
}

$roleName = "$BotName-Role"
if ([string]::IsNullOrWhiteSpace($RoleArn)) {
    try {
        $role = Invoke-AwsJson @("iam", "get-role", "--role-name", $roleName, "--output", "json")
        $RoleArn = $role.Role.Arn
        Write-Host "Using existing IAM role $roleName"
    }
    catch {
        Write-Host "Could not read existing role $roleName. Trying to create it..."
        $role = Invoke-AwsJson @("iam", "create-role", "--role-name", $roleName, "--assume-role-policy-document", "file://$trustPath", "--description", "Service role for Major Project Amazon Lex hotel booking bot", "--output", "json")
        $RoleArn = $role.Role.Arn
        Invoke-Aws @("iam", "attach-role-policy", "--role-name", $roleName, "--policy-arn", "arn:aws:iam::aws:policy/AmazonLexFullAccess") | Out-Null
        Write-Host "Created IAM role $roleName"
        Start-Sleep -Seconds 10
    }
}

$bot = Invoke-AwsJson @(
    "lexv2-models", "create-bot",
    "--region", $Region,
    "--bot-name", $BotName,
    "--description", "Major Project chatbot for booking hotel rooms and explaining room categories, price, and stay duration.",
    "--role-arn", $RoleArn,
    "--data-privacy", "file://$dataPrivacyPath",
    "--idle-session-ttl-in-seconds", "300",
    "--output", "json"
)

$botId = $bot.botId
Write-Host "Created bot $BotName ($botId)"

aws lexv2-models create-bot-locale `
    --region $Region `
    --bot-id $botId `
    --bot-version DRAFT `
    --locale-id en_US `
    --description "English locale for hotel booking." `
    --nlu-intent-confidence-threshold 0.40 | Out-Null

do {
    Start-Sleep -Seconds 5
    $locale = aws lexv2-models describe-bot-locale --region $Region --bot-id $botId --bot-version DRAFT --locale-id en_US --output json | ConvertFrom-Json
    Write-Host "Locale status: $($locale.botLocaleStatus)"
} while ($locale.botLocaleStatus -in @("Creating", "Building", "Deleting", "NotBuilt"))

$slotType = aws lexv2-models create-slot-type `
    --region $Region `
    --bot-id $botId `
    --bot-version DRAFT `
    --locale-id en_US `
    --slot-type-name "RoomType" `
    --description "Available hotel room categories with prices: Classic, Deluxe, Duplex, Family Suite, Presidential Suite." `
    --slot-type-values "file://$roomValuesPath" `
    --value-selection-setting resolutionStrategy=OriginalValue `
    --output json | ConvertFrom-Json
$roomTypeId = $slotType.slotTypeId

$intent = aws lexv2-models create-intent `
    --region $Region `
    --bot-id $botId `
    --bot-version DRAFT `
    --locale-id en_US `
    --intent-name "BookHotel" `
    --description "Collects hotel booking details and confirms room price and stay duration." `
    --sample-utterances `
        utterance="book a hotel" `
        utterance="I want to book a room" `
        utterance="reserve a hotel room" `
        utterance="book hotel for my stay" `
        utterance="I need a {RoomType} room" `
    --fulfillment-code-hook enabled=false `
    --output json | ConvertFrom-Json
$intentId = $intent.intentId

$slotSpecs = @(
    @{
        Name = "RoomType"
        TypeId = $roomTypeId
        TypeName = "RoomType"
        Prompt = "Which room category would you like? Available rooms are Classic USD 80 per night, Deluxe USD 120 per night, Duplex USD 180 per night, Family Suite USD 220 per night, and Presidential Suite USD 350 per night."
    },
    @{
        Name = "CheckInDate"
        TypeId = "AMAZON.Date"
        TypeName = "AMAZON.Date"
        Prompt = "What is your check-in date?"
    },
    @{
        Name = "CheckOutDate"
        TypeId = "AMAZON.Date"
        TypeName = "AMAZON.Date"
        Prompt = "What is your check-out date?"
    },
    @{
        Name = "Guests"
        TypeId = "AMAZON.Number"
        TypeName = "AMAZON.Number"
        Prompt = "How many guests will stay?"
    },
    @{
        Name = "Nights"
        TypeId = "AMAZON.Number"
        TypeName = "AMAZON.Number"
        Prompt = "How many days or nights will you stay?"
    }
)

$priority = 1
foreach ($spec in $slotSpecs) {
    $slot = aws lexv2-models create-slot `
        --region $Region `
        --bot-id $botId `
        --bot-version DRAFT `
        --locale-id en_US `
        --intent-id $intentId `
        --slot-name $spec.Name `
        --description "Required field for hotel booking." `
        --slot-type-id $spec.TypeId `
        --value-elicitation-setting "slotConstraint=Required,promptSpecification={messageGroups=[{message={plainTextMessage={value='$($spec.Prompt)'}}}],maxRetries=2,allowInterrupt=true}" `
        --output json | ConvertFrom-Json

    aws lexv2-models update-slot `
        --region $Region `
        --bot-id $botId `
        --bot-version DRAFT `
        --locale-id en_US `
        --intent-id $intentId `
        --slot-id $slot.slotId `
        --slot-name $spec.Name `
        --description "Required field for hotel booking." `
        --slot-type-id $spec.TypeId `
        --value-elicitation-setting "slotConstraint=Required,promptSpecification={messageGroups=[{message={plainTextMessage={value='$($spec.Prompt)'}}}],maxRetries=2,allowInterrupt=true}" | Out-Null

    $priority++
}

$slotPrioritiesPath = Join-Path $work "slot-priorities.json"
$slots = aws lexv2-models list-slots --region $Region --bot-id $botId --bot-version DRAFT --locale-id en_US --intent-id $intentId --output json | ConvertFrom-Json
$orderedPriorities = @()
$priority = 1
foreach ($name in @("RoomType", "CheckInDate", "CheckOutDate", "Guests", "Nights")) {
    $slotId = ($slots.slotSummaries | Where-Object { $_.slotName -eq $name }).slotId
    $orderedPriorities += @{ priority = $priority; slotId = $slotId }
    $priority++
}
Write-JsonFile $slotPrioritiesPath $orderedPriorities

aws lexv2-models update-intent `
    --region $Region `
    --bot-id $botId `
    --bot-version DRAFT `
    --locale-id en_US `
    --intent-id $intentId `
    --intent-name "BookHotel" `
    --description "Collects hotel booking details and confirms room price and stay duration." `
    --sample-utterances `
        utterance="book a hotel" `
        utterance="I want to book a room" `
        utterance="reserve a hotel room" `
        utterance="book hotel for my stay" `
        utterance="I need a {RoomType} room" `
    --slot-priorities "file://$slotPrioritiesPath" `
    --intent-confirmation-setting "promptSpecification={messageGroups=[{message={plainTextMessage={value='Please confirm: book a {RoomType} room from {CheckInDate} to {CheckOutDate} for {Guests} guest(s), staying {Nights} night(s). Prices per night are Classic USD 80, Deluxe USD 120, Duplex USD 180, Family Suite USD 220, and Presidential Suite USD 350.'}}}],maxRetries=2,allowInterrupt=true},declinationResponse={messageGroups=[{message={plainTextMessage={value='Okay, I have cancelled this hotel booking request.'}}}],allowInterrupt=true}" `
    --fulfillment-code-hook enabled=false `
    --intent-closing-setting "file://$closingPath" | Out-Null

aws lexv2-models build-bot-locale --region $Region --bot-id $botId --bot-version DRAFT --locale-id en_US | Out-Null
do {
    Start-Sleep -Seconds 10
    $locale = aws lexv2-models describe-bot-locale --region $Region --bot-id $botId --bot-version DRAFT --locale-id en_US --output json | ConvertFrom-Json
    Write-Host "Build status: $($locale.botLocaleStatus)"
} while ($locale.botLocaleStatus -in @("Building", "Creating"))

if ($locale.botLocaleStatus -ne "Built") {
    throw "Bot locale did not build successfully. Final status: $($locale.botLocaleStatus)"
}

$version = aws lexv2-models create-bot-version --region $Region --bot-id $botId --bot-version-locale-specification "en_US={sourceBotVersion=DRAFT}" --description "Initial hotel booking bot version." --output json | ConvertFrom-Json
$botVersion = $version.botVersion

$alias = aws lexv2-models create-bot-alias --region $Region --bot-id $botId --bot-alias-name "Production" --bot-version $botVersion --description "Production alias for the hotel booking chatbot." --output json | ConvertFrom-Json

Write-Host ""
Write-Host "DEPLOYED"
Write-Host "Region: $Region"
Write-Host "Bot name: $BotName"
Write-Host "Bot ID: $botId"
Write-Host "Bot version: $botVersion"
Write-Host "Alias: Production"
Write-Host "Alias ID: $($alias.botAliasId)"
Write-Host "Intent: BookHotel"
Write-Host "Room categories/prices: Classic USD 80, Deluxe USD 120, Duplex USD 180, Family Suite USD 220, Presidential Suite USD 350"
