# Interactive PowerShell Test Script for Amazon Lex V2 HotelBookingBot
# Run this script anytime in PowerShell: .\test_hotel_bot.ps1

$BOT_ID = "AQI4JSJRSM"
$BOT_ALIAS_ID = "TSTALIASID"
$LOCALE_ID = "en_US"
$REGION = "us-east-1"
$SESSION_ID = "user-test-" + (Get-Random)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🏨 Starting Live Chat Session with HotelBookingBot" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$userInputs = @(
    "I want to book a hotel",
    "Chicago",
    "2026-08-15",
    "3",
    "Duplex",
    "Yes"
)

foreach ($inputUtterance in $userInputs) {
    Write-Host "`n👤 User : $inputUtterance" -ForegroundColor Yellow
    
    $responseJson = aws lexv2-runtime recognize-text `
        --bot-id $BOT_ID `
        --bot-alias-id $BOT_ALIAS_ID `
        --locale-id $LOCALE_ID `
        --session-id $SESSION_ID `
        --text "$inputUtterance" `
        --region $REGION `
        --output json | ConvertFrom-Json
        
    foreach ($msg in $responseJson.messages) {
        Write-Host "🤖 Bot  : $($msg.content)" -ForegroundColor Green
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " ✅ Conversation Flow Complete!" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
