# 🏨 Amazon Lex V2 Hotel Booking Chatbot (AWS Major Project)

An end-to-end Conversational AI Chatbot built using **Amazon Lex V2** on AWS for booking hotel rooms, presenting room categories with nightly rates, confirming stay details, and issuing booking confirmations.

---

## 🎯 Features & Capabilities

- **Intent**: `BookHotel`
- **Slot Types & Categories**:
  - `Location` (`AMAZON.City`): City for hotel stay.
  - `CheckInDate` (`AMAZON.Date`): Check-in date.
  - `Nights` (`AMAZON.Number`): Stay duration in days/nights.
  - `RoomType` (Custom `RoomType` with TopResolution NLU matching):
    - 🛏️ **Classic**: $100 / night
    - 🏢 **Duplex**: $180 / night
    - 🌊 **Deluxe**: $250 / night
    - 👑 **Suite**: $400 / night
    - 💼 **Executive**: $320 / night
- **Confirmation & Fulfillment**:
  - Calculates and confirms reservation details with the user before finalizing.
  - Issues booking confirmation with reference code `#HB-94821`.

---

## 🛠️ Architecture & AWS Resources

| Resource | Resource Name / ID | Region |
|---|---|---|
| **Lex V2 Bot** | `HotelBookingBot` (`AQI4JSJRSM`) | `us-east-1` |
| **Locale** | `en_US` (English US) | `us-east-1` |
| **Intent** | `BookHotel` (`K5DGXLCD04`) | `us-east-1` |
| **Custom Slot Type** | `RoomType` (`YUG71IBEP0`) | `us-east-1` |
| **Bot Aliases** | `ProdBotAlias` (`UES8UAPLRT`), `TestBotAlias` (`TSTALIASID`) | `us-east-1` |
| **IAM Role** | `LexHotelBookingRole` | Global |

---

## 🚀 How to Run & Test

### Interactive PowerShell Script
Run the included test script to simulate a live chat session:

```powershell
.\test_hotel_bot.ps1
```

### AWS CLI Direct Command
Send a single message via CLI:

```powershell
aws lexv2-runtime recognize-text `
  --bot-id AQI4JSJRSM `
  --bot-alias-id TSTALIASID `
  --locale-id en_US `
  --session-id test-session `
  --text "I want to book a hotel room in Chicago" `
  --region us-east-1
```

---

## 📜 File Structure

```text
major/
├── README.md                  # Project documentation
├── test_hotel_bot.ps1         # PowerShell interactive test script
├── deploy-lex-hotel-bot.ps1   # Deployment script
└── .gitignore                 # Git ignore patterns
```
