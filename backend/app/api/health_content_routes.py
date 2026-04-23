from fastapi import APIRouter
from typing import List, Dict

router = APIRouter()

health_content = [

    # ================= EXERCISE =================
    # ================= EXERCISE =================

{
    "id": 1,
    "title": "PCOS Yoga Routine",
    "type": "video",
    "category": "exercise",
    "url": "https://youtu.be/5JvbjrLESPs"
},
{
    "id": 2,
    "title": "PCOD Exercise Plan",
    "type": "video",
    "category": "exercise",
    "url": "https://youtu.be/zRWUrWPWD2Y"
},

    {"id": 3, "title": "Weight Loss Home Workout", "type": "video", "category": "exercise",
     "url": "https://www.youtube.com/watch?v=UItWltVZZmE"},

    {"id": 4, "title": "Weight Gain Strength Training", "type": "video", "category": "exercise",
     "url": "https://www.youtube.com/watch?v=IODxDxX7oi4"},

    {"id": 5, "title": "Pregnancy Safe Exercises For Normal Dilevery", "type": "video", "category": "exercise",
     "url": "https://youtu.be/pH7sWPBsyiM?si=YrYOImaclsFmKn"},

    {"id": 6, "title": "Daily Full Body Stretching", "type": "video", "category": "exercise",
     "url": "https://www.youtube.com/watch?v=g_tea8ZNk5A"},

    {"id": 7, "title": "Beginner Yoga for Flexibility", "type": "video", "category": "exercise",
     "url": "https://www.youtube.com/watch?v=v7AYKMP6rOE"},

    {"id": 8, "title": "Cardio Workout at Home", "type": "video", "category": "exercise",
     "url": "https://www.youtube.com/watch?v=ml6cT4AZdqI"},

    # ================= DIET =================
    # ================= DIET (REAL LINKS) =================

{
    "id": 9,
    "title": "Weight Loss Diet Chart (Male/Female)",
    "type": "link",
    "category": "diet",
    "url": "https://www.blkmaxhospital.com/blogs/diet-chart-weight-loss-female-male"
},
{
    "id": 10,
    "title": "Diet Chart for Diabetic Patients",
    "type": "link",
    "category": "diet",
    "url": "https://www.nanavatimaxhospital.org/blogs/diet-chart-for-diabetic-patients"
},
{
    "id": 11,
    "title": "Weight Gain Diet Plan",
    "type": "link",
    "category": "diet",
    "url": "https://www.blkmaxhospital.com/blogs/weight-gain-diet-plan-chart"
},
{
    "id": 12,
    "title": "High Cholesterol Diet Chart",
    "type": "link",
    "category": "diet",
    "url": "https://www.lybrate.com/topic/high-cholesterol-diet-chart"
},
{
    "id": 13,
    "title": "Muscle Gain Diet Plan",
    "type": "link",
    "category": "diet",
    "url": "https://www.lybrate.com/topic/muscle-gain-diet-chart"
},
{
    "id": 14,
    "title": "Healthy Diet for Kids",
    "type": "link",
    "category": "diet",
    "url": "https://nutritionsource.hsph.harvard.edu/kids-healthy-eating-plate/"
},
{
    "id": 15,
    "title": "Kidney & Dialysis Patient Diet",
    "type": "link",
    "category": "diet",
    "url": "https://www.tataaig.com/knowledge-center/health-insurance/diet-chart-for-kidney-and-dialysis-patients"
},
{
    "id": 16,
    "title": "Balanced Diet for Healthy Lifestyle",
    "type": "link",
    "category": "diet",
    "url": "https://www.maxhealthcare.in/blogs/what-is-a-balanced-diet"
},
{
    "id": 17,
    "title": "PCOD Diet Plan for Women",
    "type": "link",
    "category": "diet",
    "url": "https://www.nanavatimaxhospital.org/blogs/pcod-diet-chart"
},
{
    "id": 18,
    "title": "PCOS Diet Plan for Women",
    "type": "link",
    "category": "diet",
    "url": "https://www.asterdmhealthcare.com/health-library/pcos-diet-symptoms-causes-foods-diet-plan"
},

    # ================= HEALTH ARTICLES =================
    # ================= HEALTH ARTICLES (REAL LINKS) =================

{
    "id": 19,
    "title": "Fetal Weight Estimation vs Clinical Assessment",
    "type": "link",
    "category": "health",
    "url": "https://link.springer.com/article/10.1186/s12884-026-08871-2"
},
{
    "id": 20,
    "title": "Fear of Childbirth & Cesarean Section Risk",
    "type": "link",
    "category": "health",
    "url": "https://link.springer.com/article/10.1186/s12884-026-08981-x"
},
{
    "id": 21,
    "title": "Autism Risk Genes Across Ancestries",
    "type": "link",
    "category": "health",
    "url": "https://www.nature.com/articles/s41591-026-04259-z"
},
{
    "id": 22,
    "title": "Diet & Ischemic Heart Disease Risk",
    "type": "link",
    "category": "health",
    "url": "https://www.nature.com/articles/s41591-026-04321-w"
},
{
    "id": 23,
    "title": "Aquatic Virus Transmission to Humans",
    "type": "link",
    "category": "health",
    "url": "https://www.nature.com/articles/s41564-026-02306-6"
},
{
    "id":24 ,
    "title": "Achromobacter Bacteremia in Cancer Patients",
    "type": "link",
    "category": "health",
    "url": "https://journals.lww.com/infectdis/abstract/2026/05010/achromobacter_bacteremia_in_immunocompromised.37.aspx"
},
{
    "id":25,
    "title": "Fusobacterium Lung Infection Case Study",
    "type": "link",
    "category": "health",
    "url": "https://journals.lww.com/infectdis/abstract/2026/05010/fusobacterium_nucleatum_lung_abscess_following.38.aspx"
},
{
    "id": 26,
    "title": "Midwives & Maternal Healthcare Improvement",
    "type": "link",
    "category": "health",
    "url": "https://idronline.org/article/health/midwives-the-missing-link-to-improved-maternal-healthcare/"
},
{
    "id": 27,
    "title": "Sudden Cardiac Death Explained",
    "type": "link",
    "category": "health",
    "url": "https://www.baker.edu.au/health-hub/fact-sheets/sudden-cardiac-death"
},
{
    "id": 28,
    "title": "Postpartum Psychological Disorders Study",
    "type": "link",
    "category": "health",
    "url": "https://link.springer.com/article/10.1186/s12884-026-09020-5"
},
]

@router.get("/health-content", response_model=List[Dict])
def get_health_content():
    return health_content