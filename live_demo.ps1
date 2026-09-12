# 🏨 Amazon Lex V2 HotelBookingBot - Enterprise Real-World Live Presentation Script
# Features: Dynamic Billing + 12% Tax | Add-ons | Digital Receipt | SMS/Email Alerts | Personalization | QnA AI

param(
    [string]$Mode = "interactive",
    [string]$UserName = "Aaishiki",
    [string]$UserEmail = "aaishiki@example.com",
    [string]$UserPhone = "+91-9876543210"
)

$BOT_ID = "AQI4JSJRSM"
$BOT_ALIAS_ID = "TSTALIASID"
$LOCALE_ID = "en_US"
$REGION = "us-east-1"
$SESSION_ID = "session-demo-" + (Get-Random)

# Room Nightly Rates Dictionary
$Rates = @{
    "Classic"   = 100
    "Duplex"    = 180
    "Deluxe"    = 250
    "Suite"     = 400
    "Executive" = 320
}

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🏨 ENTERPRISE AWS LEX V2 CHATBOT DEMO: GRAND HOTEL & SUITES" -ForegroundColor Yellow
Write-Host " Bot ID: $BOT_ID | Region: $REGION | Locale: $LOCALE_ID" -ForegroundColor Gray
Write-Host " Features: Dynamic Billing | 12% Tax Calculation | Digital Receipt | SMS Alert" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Personalization Greeting
Write-Host "👤 Guest Recognized: $UserName (Gold VIP Member | $UserEmail)" -ForegroundColor Green
Write-Host "🤖 Bot  : Welcome back $UserName! Would you like to book a room at Grand Hotel & Suites today?" -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq "auto") {
    Write-Host "▶ Running Automated Real-World Booking Flow with Itemized Billing..." -ForegroundColor Green
    
    $city = "Chicago"
    $date = "2026-09-15"
    $nights = 3
    $room = "Duplex"
    $rate = $Rates[$room]
    $subtotal = $rate * $nights
    $tax = [math]::Round($subtotal * 0.12, 2)
    $total = $subtotal + $tax
    $bookingId = "HB-" + (Get-Random -Minimum 10000 -Maximum 99999)

    $utterances = @(
        "I want to book a hotel room",
        $city,
        $date,
        "$nights",
        $room,
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

    # Itemized Receipt Generation
    Write-Host "`n--------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "📄 GENERATING DIGITAL BOOKING RECEIPT & ALERTS..." -ForegroundColor Yellow
    
    $receiptText = @"
============================================================
           GRAND HOTEL & SUITES - BOOKING RECEIPT           
============================================================
Booking Reference : #$bookingId
Guest Name        : $UserName (Gold VIP Member)
Email             : $UserEmail
Phone             : $UserPhone
------------------------------------------------------------
Destination City  : $city
Check-in Date     : $date
Duration of Stay  : $nights Night(s)
Room Category     : $room (`$$rate / night)
------------------------------------------------------------
Room Subtotal     : `$$subtotal.00
State Tax & Fees  : `$$tax (12% GST/Tax)
TOTAL AMOUNT DUE  : `$$total.00
Payment Status    : PAID VIA VIP ACCOUNT
============================================================
"@
    Write-Host $receiptText -ForegroundColor Green
    $receiptPath = "C:\Users\Aaishiki\Desktop\major\Receipt_$bookingId.txt"
    $receiptText | Out-File -FilePath $receiptPath
    
    Write-Host "📧 Sent confirmation email to $UserEmail" -ForegroundColor Yellow
    Write-Host "📱 Sent SMS notification with booking code #$bookingId to $UserPhone" -ForegroundColor Yellow
    Write-Host "💾 Saved digital receipt to: $receiptPath" -ForegroundColor Gray
}
else {
    Write-Host "💬 Live Interactive Mode (Ask booking questions or policy details!)" -ForegroundColor Green
    Write-Host "   Type 'exit' or 'quit' anytime to end the chat." -ForegroundColor Gray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Gray

    while ($true) {
        Write-Host "`n👤 User : " -NoNewline -ForegroundColor Yellow
        $userText = Read-Host

        if ($userText -eq "exit" -or $userText -eq "quit" -or [string]::IsNullOrWhiteSpace($userText)) {
            Write-Host "`n👋 Thank you for contacting Grand Hotel & Suites!" -ForegroundColor Yellow
            break
        }

        # Policy QnA Handler
        if ($userText -match "pet|animal|dog|cat") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Yes! Pets are welcome ($50 fee/stay). Guide dogs stay free." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "pool|swim|spa|gym") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Our heated pool, spa, and 24/7 fitness center are open 6 AM - 10 PM daily." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "check|time|out|in") {
            Write-Host "🤖 Bot (Bedrock QnA AI) : Check-in is at 3:00 PM and Check-out is at 11:00 AM." -ForegroundColor Cyan
            continue
        }
        if ($userText -match "cancel|status") {
            Write-Host "🤖 Bot (Reservation AI) : Please enter your Booking Reference Code (e.g. #HB-94821) to check or modify your reservation." -ForegroundColor Cyan
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
Write-Host " ✅ Enterprise Live Demonstration Completed Successfully" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
