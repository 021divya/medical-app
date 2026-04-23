# services/chat_service.py
def process_message(user_id, message_text, db):
    # Just save to DB
    save_to_db(user_id, message_text)
    return "Message Sent"