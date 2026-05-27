def get_patient_input():
    """
    Temporary hard-coded patient input.
    Later this will come from chatbot / API.
    """

    patient = {
        "area": "dwarka",
        "latitude": 28.5921,
        "longitude": 77.0460,
        "max_distance_km": 5,    
        "max_fees": 2000,         
        "min_rating": 4.0         
    }

    return patient


# Test
if __name__ == "__main__":
    patient = get_patient_input()
    print("👤 Patient Input:")
    for k, v in patient.items():
        print(f"{k}: {v}")
