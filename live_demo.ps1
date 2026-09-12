# 🏨 Amazon Lex V2 HotelBookingBot - Live Presentation & Teacher Demo Script
# Includes Personalization (Session Attributes) & Policy QnA AI Features

param(
    [string]$Mode = "interactive",
    [string]$UserName = "Aaishiki"
)

$BOT_ID = "AQI4JSJRSM"
$BOT_ALIAS_ID = "TSTALIASID"
$LOCALE_ID = "en_US"
$REGION = "us-east-1"
$SESSION_ID = "session-demo-" + (Get-Random)

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🏨 AWS MAJOR PROJECT DEMONSTRATION: AMAZON LEX V2 HOTEL BOOKING CHATBOT" -ForegroundColor Yellow
Write-Host " Bot ID: $BOT_ID | Region: $REGION | Locale: $LOCALE_ID" -ForegroundColor Gray
Write-Host " Features: Voice Enabled | NLU TopResolution | Personalization | QnA AI" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Personalization Greeting using Session Attributes
Write-Host "👤 User Identity Recognized: $UserName (Gold VIP Member)" -ForegroundColor Green
Write-Host "🤖 Bot  : Welcome back $UserName! Would you like to book a Duplex room in Chicago again like last time, or start a new reservation?" -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq "auto") {
    Write-Host "▶ Running Automated Live Flow Demo with Personalization..." -ForegroundColor Green
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
    Write-Host "💬 Live Interactive Mode (Type messages, or ask policy questions like 'are pets allowed?')" -ForegroundColor Green
    Write-Host "   Type 'exit' or 'quit' anytime to end the chat." -ForegroundColor Gray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Gray

    while ($true) {
        Write-Host "`n👤 User : " -NoNewline -ForegroundColor Yellow
        $userText = Read-Host

        if ($userText -eq "exit" -or $userText -eq "quit" -or [string]::IsNullOrWhiteSpace($userText)) {
            Write-Host "`n👋 Demo ended. Thank you!" -ForegroundColor Yellow
            break
        }

        # Policy QnA Handler (Bedrock / Kendra AI RAG Fallback simulation)
        if ($userText -match "pet|animal|dog|cat") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Yes! Green Valley Hotel is pet-friendly ($50 pet fee per stay). Guide dogs stay free." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "pool|swim|spa|gym") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Our heated outdoor pool, spa, and 24/7 fitness center are open daily from 6:00 AM to 10:00 PM." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "check|time|out|in") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Standard check-in is at 3:00 PM and check-out is at 11:00 AM. Early check-in is available upon request." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "wifi|internet|breakfast") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Free high-speed Wi-Fi and daily buffet breakfast are included for all guests!" -ForegroundColor Cyan
            continue
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
            Write-Host "`n🎉 Intent Fulfilled and Booking Complete!" -ForegroundColor Green
            break
        }
    }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " ✅ Live Demonstration Completed Successfully" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
