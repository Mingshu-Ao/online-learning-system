from fastapi import FastAPI, File, Form, UploadFile

from app.schemas import (
    AiAskRequest,
    AiAssistantResponse,
    HealthResponse,
    RecommendationItem,
    SolveQuestionRequest,
    SolveQuestionResponse,
)

app = FastAPI(
    title="Online Learning AI Service",
    version="0.0.1",
    description="AI microservice skeleton for online learning system.",
)


def build_ai_response(question_text: str, source: str) -> AiAssistantResponse:
    return AiAssistantResponse(
        question_text=question_text,
        knowledge_points=["placeholder-knowledge-point"],
        difficulty="BEGINNER",
        solution_steps=[
            f"Receive the {source} request from the main backend.",
            "Run the placeholder reasoning pipeline.",
            "Return structured explanation data for the main system to persist and audit.",
        ],
        mistake_analysis="This is a scaffold response and should be replaced by a real model pipeline.",
        recommendations=[
            RecommendationItem(
                type="VIDEO",
                resource_id=None,
                title="Placeholder recommendation",
                reason="The backend will filter and enrich these recommendations before exposing them to learners.",
            )
        ],
    )


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(service="online-learning-ai-service", status="UP", version="0.0.1")


@app.post("/api/v1/solve-question", response_model=SolveQuestionResponse)
def solve_question(payload: SolveQuestionRequest) -> SolveQuestionResponse:
    response = build_ai_response(payload.question_text, "legacy solve-question")
    return SolveQuestionResponse(
        question_text=response.question_text,
        knowledge_points=response.knowledge_points,
        solution_steps=response.solution_steps,
        recommendations=response.recommendations,
    )


@app.post("/ai/ask", response_model=AiAssistantResponse)
def ask(payload: AiAskRequest) -> AiAssistantResponse:
    return build_ai_response(payload.question, "text ask")


@app.post("/ai/solve-image", response_model=AiAssistantResponse)
async def solve_image(
    user_id: int = Form(...),
    course_id: int = Form(...),
    image: UploadFile = File(...),
) -> AiAssistantResponse:
    file_hint = image.filename or f"course-{course_id}-question"
    question_text = f"Image question uploaded by user {user_id}: {file_hint}"
    return build_ai_response(question_text, "image solve")
