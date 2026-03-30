from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed",
    model="llama-3.1-8b",
    temperature=0.7,
)

response = llm.invoke([
    SystemMessage(content="You are a helpful assistant specialised in Agentic Business Transformation. Provide all answers in Markdown."),
    HumanMessage(content="Generate a project plan for putting a Python-based AI Agent into production.")
])

print(response.content)