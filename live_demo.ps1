# 🏨 Amazon Lex V2 HotelBookingBot - Live Presentation & Teacher Demo Script
# Run in PowerShell: .\live_demo.ps1

param(
    [string]$Mode = "interactive"
)

$BOT_ID = "AQI4JSJRSM"
$BOT_ALIAS_ID = "TSTALIASID"
$LOCALE_ID = "en_US"
$REGION = "us-east-1"
$SESSION_ID = "teacher-demo-" + (Get-Random)

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🏨 AWS MAJOR PROJECT DEMONSTRATION: AMAZON LEX V2 HOTEL BOOKING CHATBOT" -ForegroundColor Yellow
Write-Host " Bot ID: $BOT_ID | Region: $REGION | Locale: $LOCALE_ID" -ForegroundColor Gray
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq "auto") {
    Write-Host "▶ Running Automated Live Flow Demo..." -ForegroundColor Green
    $utterances = @(
        "I want to book a hotel room",
        "Chicago",
        "2026-09-15",
        "3",
        "Duplex",
        "Yes"
    )

    foreach ($text in $utterances) {
        Start-Sleep -Seconds 1
        Write-Host "`n👤 User : " -NoNewline -ForegroundColor Yellow
        Write-Host "$text" -ForegroundColor White
        
        $res = python -m awscli lexv2-runtime recognize-text `
            --bot-id $BOT_ID `
            --bot-alias-id $BOT_ALIAS_ID `
            --locale-id $LOCALE_ID `
            --session-id $SESSION_ID `
            --text "$text" `
            --region $REGION `
            --output json | ConvertFrom-Json
            
        foreach ($msg in $res.messages) {
            Write-Host "🤖 Bot  : " -NoNewline -ForegroundColor Green
            Write-Host "$($msg.content)" -ForegroundColor Cyan
        }
    }
}
else {
    Write-Host "💬 Live Interactive Mode (Type messages directly to the bot!)" -ForegroundColor Green
    Write-Host "   Type 'exit' or 'quit' anytime to end the chat." -ForegroundColor Gray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Gray

    # Initial trigger
    $initialText = "I want to book a hotel"
    Write-Host "`n👤 User : $initialText" -ForegroundColor Yellow

    $res = python -m awscli lexv2-runtime recognize-text `
        --bot-id $BOT_ID `
        --bot-alias-id $BOT_ALIAS_ID `
        --locale-id $LOCALE_ID `
        --session-id $SESSION_ID `
        --text "$initialText" `
        --region $REGION `
        --output json | ConvertFrom-Json

    foreach ($msg in $res.messages) {
        Write-Host "🤖 Bot  : $($msg.content)" -ForegroundColor Cyan
    }

    while ($true) {
        Write-Host "`n👤 User : " -NoNewline -ForegroundColor Yellow
        $userText = Read-Host

        if ($userText -eq "exit" -or $userText -eq "quit" -or [string]::IsNullOrWhiteSpace($userText)) {
            Write-Host "`n👋 Demo ended. Thank you!" -ForegroundColor Yellow
            break
        }

        $res = python -m awscli lexv2-runtime recognize-text `
            --bot-id $BOT_ID `
            --bot-alias-id $BOT_ALIAS_ID `
            --locale-id $LOCALE_ID `
            --session-id $SESSION_ID `
            --text "$userText" `
            --region $REGION `
            --output json | ConvertFrom-Json

        foreach ($msg in $res.messages) {
            Write-Host "🤖 Bot  : $($msg.content)" -ForegroundColor Cyan
        }

        if ($res.sessionState.dialogAction.type -eq "Close") {
            Write-Host "`n🎉 Intent Fulfilled & Booking Complete!" -ForegroundColor Green
            break
        }
    }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " ✅ Live Demonstration Completed Successfully" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
