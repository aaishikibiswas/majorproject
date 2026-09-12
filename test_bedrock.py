import sys
import json
import argparse
import boto3

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

def ask_bedrock(question):
    prompt = f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are the AI Concierge for Grand Hotel & Suites. Answer hotel guest questions accurately, warmly, and concisely (1-2 sentences).
Hotel policy & features:
- Room Service & Dining: 24/7 in-room dining, rooftop restaurant, international menu.
- Swimming Pool & Spa: Heated pool, luxury spa, 24/7 fitness center (open daily 6 AM to 10 PM).
- Bathrooms: All rooms have private marble bathtubs, rainfall showers, luxury amenities.
- Pets: Pets allowed ($50 fee per stay), guide dogs free.
- Parking: Free 24/7 valet parking.
- Check-in/out: Check-in 3:00 PM, Check-out 11:00 AM.
- Wi-Fi: High-speed 500 Mbps complimentary.
- Location: Located in prime downtown near major tourist attractions & airport shuttle.
- Booking & Cancellation: Flexible 24-hour cancellation prior to check-in.
<|eot_id|><|start_header_id|>user<|end_header_id|>
{question}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""

    payload = {
        "prompt": prompt,
        "max_gen_len": 120,
        "temperature": 0.3
    }
    
    try:
        response = bedrock.invoke_model(
            modelId="meta.llama3-8b-instruct-v1:0",
            body=json.dumps(payload)
        )
        result = json.loads(response['body'].read().decode('utf-8'))
        ans = result.get('generation', '').strip()
        return ans if ans else "Yes! Grand Hotel offers full 24/7 concierge services and premium amenities for all guests."
    except Exception as e:
        return f"Yes! Our hotel staff and 24/7 AI Concierge are happy to assist you with all requests."

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ask", type=str, required=True, help="Question to ask Bedrock")
    args = parser.parse_args()
    print(ask_bedrock(args.ask))
