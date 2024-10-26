import firebase_admin
from firebase_admin import credentials, firestore

# Path to your Firebase service account key
cred = credentials.Certificate('C:\\Users\\harih\\Downloads\\techwiz-app-ec16f-firebase-adminsdk-u5awu-d08c3b1b2b.json')
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

# Full content to be pushed to Firestore
terms_data = {
    'sections': [
        {
            'title': '1. Information We Collect',
            'content': 'We gather information that users provide directly when creating accounts, completing forms, or communicating with us. '
                       'We also collect data automatically during site visits and through third-party sources to improve our services. '
                       'This includes:\n\n'
                       '- Account and profile information, including names, contact details, and payment details.\n'
                       '- Activity data, including site interactions and communications.'
        },
        {
            'title': '2. Legal Basis for Data Processing',
            'content': 'We process personal data based on several lawful grounds:\n\n'
                       '- Consent: When you give us permission to use your data for specific purposes.\n'
                       '- Contractual Need: To fulfill obligations or provide services requested by you.\n'
                       '- Legal Compliance: To adhere to laws or regulations.\n'
                       '- Legitimate Interests: To enhance our platform, prevent fraud, and ensure security.'
        },
        {
            'title': '3. How We Use Your Information',
            'content': 'We use your personal information to:\n\n'
                       '- Provide and improve our services.\n'
                       '- Ensure platform security and integrity.\n'
                       '- Prevent fraud and illegal activities.\n'
                       '- Communicate with you when requested.\n'
                       '- Fulfill legal and regulatory obligations.'
        },
        {
            'title': '4. Data Retention',
            'content': 'We retain personal information for as long as necessary to fulfill the purposes outlined in this Policy. '
                       'However, we may retain data for extended periods to comply with legal obligations or resolve disputes.'
        },
        {
            'title': '5. Children\'s Privacy',
            'content': 'Dial2Tech is not intended for users under the age of 18. If you\'re between 13 and 18, you may use the platform only under the supervision of a parent or guardian. '
                       'We do not knowingly collect data from children under 13.'
        },
        {
            'title': '6. Sharing Data with Third Parties',
            'content': 'We may share your data with third-party service providers to deliver our services, comply with legal obligations, or prevent fraud. '
                       'Your data may also be processed in other jurisdictions by third-party partners.'
        },
        {
            'title': '7. Cookies',
            'content': 'We use cookies and similar technologies to enhance user experience, improve performance, and deliver personalized content. '
                       'You can manage cookie preferences in your browser settings.'
        },
        {
            'title': '8. Security',
            'content': 'We employ industry-standard security measures to protect your personal information from unauthorized access, loss, or misuse. '
                       'However, no security system is 100% foolproof, and we encourage users to take steps to protect their own data.'
        },
        {
            'title': '9. Regional Provisions',
            'content': 'Users in different regions, including the EU, UK, and US, may have specific rights regarding their data. '
                       'Refer to the relevant section in the full Policy for more details on your rights.'
        },
        {
            'title': '10. Updating Your Information',
            'content': 'You can update your personal information through your account settings. If you notice any inaccuracies, please contact us to correct them.'
        },
        {
            'title': '11. Contact Us',
            'content': 'For privacy-related concerns, please reach out to our support team at privacy@dial2tech.com.'
        }
    ]
}

# Pushing data to Firestore
doc_ref = db.collection('Terms_and_condition').document('I54o9VqBaDtuR07c4mYL')
doc_ref.set(terms_data)

print("Data has been pushed to Firestore successfully.")
