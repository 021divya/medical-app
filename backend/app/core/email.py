import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

EMAIL_ADDRESS = "singhmilli959@gmail.com"
EMAIL_PASSWORD = "wmbf huyg fdce qmxd"


def send_otp_email(to_email: str, otp: str):

    subject = "AI Medical App - Password Reset OTP"

    body = f"""
Hello,

Your OTP for resetting your password is:

{otp}

This OTP will expire in 5 minutes.

If you did not request this, please ignore this email.

AI Medical App
"""

    message = MIMEMultipart()
    message["From"] = EMAIL_ADDRESS
    message["To"] = to_email
    message["Subject"] = subject

    message.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
    server.starttls()

    server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)

    server.sendmail(EMAIL_ADDRESS, to_email, message.as_string())

    server.quit()