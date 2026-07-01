from typing import List, Optional

from pydantic import BaseModel, Field


class SolveQuestionRequest(BaseModel):
    question_text: str = Field(..., min_length=1, description="Original user question")
    image_url: Optional[str] = Field(default=None, description="Optional uploaded image URL")


class AiAskRequest(BaseModel):
    user_id: int
    course_id: int
    question: str = Field(..., min_length=1)


class RecommendationItem(BaseModel):
    type: str
    title: Optional[str] = None
    resource_id: Optional[int] = None
    reason: str


class SolveQuestionResponse(BaseModel):
    question_text: str
    knowledge_points: List[str]
    solution_steps: List[str]
    recommendations: List[RecommendationItem]


class AiAssistantResponse(BaseModel):
    question_text: str
    knowledge_points: List[str]
    difficulty: Optional[str] = None
    solution_steps: List[str]
    mistake_analysis: Optional[str] = None
    recommendations: List[RecommendationItem]


class HealthResponse(BaseModel):
    service: str
    status: str
    version: str
