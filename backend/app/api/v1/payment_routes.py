from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import hmac
import hashlib
import os
import app
from app.services.razorpay_service import create_order as razorpay_create_order

router = APIRouter()

class OrderRequest(BaseModel):
    amount: int

class VerifyRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

@app.post("/api/v1/payment/create_order")
def create_order(req: OrderRequest):
    return {
        "id": "order_dummy_12345",
        "amount": req.amount,
        "currency": "INR",
        "status": "created"
    }

@app.post("/api/v1/payment/verify")
def verify_payment(req: VerifyRequest):
    return {
        "status": "ok",
        "verified": True
    }